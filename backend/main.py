import hashlib
import secrets
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr, Field

DB_PATH = Path(__file__).parent / 'app.db'

app = FastAPI(title='PCMonitor API', version='1.0.0')
app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)


@app.middleware('http')
async def normalize_double_slashes(request: Request, call_next: Any) -> Any:
    path = request.scope.get('path', '/')
    if '//' in path:
        normalized = '/' + '/'.join(part for part in path.split('/') if part)
        request.scope['path'] = normalized or '/'
    return await call_next(request)


@app.get('/')
def root() -> dict[str, str]:
    return {'status': 'ok', 'service': 'pcmonitor-backend'}


class RegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=60)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class SystemStatsDto(BaseModel):
    cpuLoad: float
    ramUsage: float
    temperature: float
    uptime: str


class StationDto(BaseModel):
    id: str
    name: str
    isOn: bool = False
    stats: SystemStatsDto


class StationsUpdateRequest(BaseModel):
    stations: list[StationDto]


@dataclass
class UserRecord:
    id: int
    name: str
    email: str


def db() -> sqlite3.Connection:
    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row
    return connection


def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode('utf-8')).hexdigest()


def init_db() -> None:
    with db() as conn:
        conn.execute(
            '''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL
            )
            ''',
        )
        conn.execute(
            '''
            CREATE TABLE IF NOT EXISTS tokens (
                token TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(user_id) REFERENCES users(id)
            )
            ''',
        )
        conn.execute(
            '''
            CREATE TABLE IF NOT EXISTS stations (
                id TEXT NOT NULL,
                user_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                is_on INTEGER NOT NULL DEFAULT 0,
                cpu_load REAL NOT NULL,
                ram_usage REAL NOT NULL,
                temperature REAL NOT NULL,
                uptime TEXT NOT NULL,
                PRIMARY KEY(id, user_id),
                FOREIGN KEY(user_id) REFERENCES users(id)
            )
            ''',
        )


def create_default_station(conn: sqlite3.Connection, user_id: int) -> None:
    conn.execute(
        '''
        INSERT OR REPLACE INTO stations (
            id,
            user_id,
            name,
            is_on,
            cpu_load,
            ram_usage,
            temperature,
            uptime
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        ('st-main', user_id, 'Main Server', 0, 10.0, 2048.0, 40.0, '0h 0m'),
    )


def read_user_by_email(conn: sqlite3.Connection, email: str) -> sqlite3.Row | None:
    return conn.execute(
        'SELECT id, name, email, password_hash FROM users WHERE email = ?',
        (email.lower().strip(),),
    ).fetchone()


def read_user_from_token(token: str) -> UserRecord:
    with db() as conn:
        row = conn.execute(
            '''
            SELECT u.id, u.name, u.email
            FROM users u
            JOIN tokens t ON t.user_id = u.id
            WHERE t.token = ?
            ''',
            (token,),
        ).fetchone()

    if row is None:
        raise HTTPException(status_code=401, detail='Invalid token')

    return UserRecord(id=row['id'], name=row['name'], email=row['email'])


def read_stations(conn: sqlite3.Connection, user_id: int) -> list[dict[str, Any]]:
    rows = conn.execute(
        '''
        SELECT id, name, is_on, cpu_load, ram_usage, temperature, uptime
        FROM stations
        WHERE user_id = ?
        ORDER BY id
        ''',
        (user_id,),
    ).fetchall()

    result: list[dict[str, Any]] = []
    for row in rows:
        result.append(
            {
                'id': row['id'],
                'name': row['name'],
                'isOn': bool(row['is_on']),
                'stats': {
                    'cpuLoad': row['cpu_load'],
                    'ramUsage': row['ram_usage'],
                    'temperature': row['temperature'],
                    'uptime': row['uptime'],
                },
            },
        )
    return result


def bearer_token(authorization: str | None) -> str:
    if authorization is None or not authorization.startswith('Bearer '):
        raise HTTPException(status_code=401, detail='Missing bearer token')
    return authorization.removeprefix('Bearer ').strip()


@app.on_event('startup')
def on_startup() -> None:
    init_db()


@app.post('/auth/register', status_code=201)
def register(payload: RegisterRequest) -> dict[str, Any]:
    with db() as conn:
        existing = read_user_by_email(conn, payload.email)
        if existing is not None:
            raise HTTPException(status_code=409, detail='Email already exists')

        cursor = conn.execute(
            '''
            INSERT INTO users (name, email, password_hash)
            VALUES (?, ?, ?)
            ''',
            (
                payload.name.strip(),
                payload.email.lower().strip(),
                hash_password(payload.password),
            ),
        )
        user_id = int(cursor.lastrowid)
        create_default_station(conn, user_id)

    return {
        'id': user_id,
        'name': payload.name.strip(),
        'email': payload.email.lower().strip(),
    }


@app.post('/auth/login')
def login(payload: LoginRequest) -> dict[str, str]:
    with db() as conn:
        user = read_user_by_email(conn, payload.email)
        if user is None or user['password_hash'] != hash_password(payload.password):
            raise HTTPException(status_code=401, detail='Invalid credentials')

        token = secrets.token_urlsafe(32)
        conn.execute(
            'INSERT INTO tokens (token, user_id) VALUES (?, ?)',
            (token, user['id']),
        )

    return {'access_token': token, 'token_type': 'bearer'}


@app.get('/auth/profile')
def profile(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    token = bearer_token(authorization)
    user = read_user_from_token(token)

    with db() as conn:
        stations = read_stations(conn, user.id)

    return {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'stations': stations,
    }


@app.put('/auth/stations')
def update_stations(
    payload: StationsUpdateRequest,
    authorization: str | None = Header(default=None),
) -> dict[str, Any]:
    token = bearer_token(authorization)
    user = read_user_from_token(token)

    with db() as conn:
        conn.execute('DELETE FROM stations WHERE user_id = ?', (user.id,))
        for station in payload.stations:
            conn.execute(
                '''
                INSERT INTO stations (
                    id,
                    user_id,
                    name,
                    is_on,
                    cpu_load,
                    ram_usage,
                    temperature,
                    uptime
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ''',
                (
                    station.id,
                    user.id,
                    station.name,
                    int(station.isOn),
                    station.stats.cpuLoad,
                    station.stats.ramUsage,
                    station.stats.temperature,
                    station.stats.uptime,
                ),
            )

        stations = read_stations(conn, user.id)

    return {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'stations': stations,
    }
