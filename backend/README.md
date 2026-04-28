# PCMonitor Backend (Python)

Simple FastAPI + SQLite backend for the mobile app.

## Features

- Register user
- Login with token
- Get profile by token
- Save user stations in SQLite

## Run

1. Create virtual environment:

```bash
python -m venv .venv
```

2. Activate it:

```bash
.venv\\Scripts\\activate
```

3. Install dependencies:

```bash
pip install -r requirements.txt
```

4. Start server:

```bash
python -m uvicorn main:app --reload 
```

## API

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/profile` (Bearer token)
- `PUT /auth/stations` (Bearer token)

## Flutter base URL

The Flutter app reads API URL from `API_BASE_URL` compile-time define.
Default is `http://10.0.2.2:8000` (Android emulator).

Examples:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```
