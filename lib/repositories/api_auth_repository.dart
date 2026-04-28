import 'dart:convert';

import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/models/system_stats.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/repositories/i_auth_repository.dart';
import 'package:flutter_app/repositories/local_auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiAuthRepository extends IAuthRepository {
  static const _tokenKey = 'auth_token';
  static const _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static final _baseUrl = _rawBaseUrl.endsWith('/')
      ? _rawBaseUrl.substring(0, _rawBaseUrl.length - 1)
      : _rawBaseUrl;

  static final _loginUrl = Uri.parse('$_baseUrl/auth/login');
  static final _registerUrl = Uri.parse('$_baseUrl/auth/register');
  static final _profileUrl = Uri.parse('$_baseUrl/auth/profile');
  static final _stationsUrl = Uri.parse('$_baseUrl/auth/stations');

  final LocalAuthRepository _local = LocalAuthRepository();

  @override
  Future<void> registerUser(User user) async {
    try {
      await _registerRemote(user);
      final token = await _requestToken(user.email, user.password);
      if (token != null) {
        await _saveToken(token);
      }
    } catch (_) {
      // Keep local flow available if backend is unreachable.
    }

    await _local.registerUser(user);
  }

  @override
  Future<User?> login(String email, String password) async {
    try {
      final token = await _requestToken(email, password);
      if (token == null) {
        return _local.login(email, password);
      }

      final remoteUser = await _fetchProfile(token, password, email);
      await _saveToken(token);
      await _local.registerUser(remoteUser);
      return remoteUser;
    } catch (_) {
      return _local.login(email, password);
    }
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await _local.clearSession();
  }

  Future<void> syncStations(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return;
    }

    final payload = jsonEncode(
      {'stations': user.stations.map((station) => station.toJson()).toList()},
    );

    final response = await http.put(
      _stationsUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: payload,
    );

    if (response.statusCode != 200) {
      throw Exception('Stations sync failed: ${response.statusCode}');
    }
  }

  Future<void> _registerRemote(User user) async {
    final payload = jsonEncode(
      {'name': user.name, 'email': user.email, 'password': user.password},
    );

    final response = await http.post(
      _registerUrl,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (response.statusCode != 201) {
      throw Exception('Remote register failed');
    }
  }

  Future<String?> _requestToken(String email, String password) async {
    final payload = jsonEncode({'email': email, 'password': password});
    final response = await http.post(
      _loginUrl,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['access_token'] as String?;
  }

  Future<User> _fetchProfile(
    String token,
    String password,
    String fallbackEmail,
  ) async {
    final response = await http.get(
      _profileUrl,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Profile request failed');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final email = decoded['email']?.toString() ?? fallbackEmail;
    final cached = await _local.findUserByEmail(email);
    final stations = _extractStations(decoded);

    return User(
      name: decoded['name']?.toString() ?? cached?.name ?? 'Remote user',
      email: email,
      password: password,
      stations: stations.isEmpty
          ? cached?.stations ?? _buildDefaultStations()
          : stations,
    );
  }

  List<Station> _extractStations(Map<String, dynamic> json) {
    final raw = json['stations'];
    if (raw is! List<dynamic>) {
      return const <Station>[];
    }

    return raw.whereType<Map<String, dynamic>>().map(Station.fromJson).toList();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  List<Station> _buildDefaultStations() {
    return [
      Station(
        id: 'api-st-1',
        name: 'Cloud Station',
        stats: const SystemStats(
          cpuLoad: 15,
          ramUsage: 3072,
          temperature: 36,
          uptime: '1h 20m',
        ),
      ),
    ];
  }
}
