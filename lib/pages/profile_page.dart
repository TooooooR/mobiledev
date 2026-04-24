import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/repositories/api_auth_repository.dart';
import 'package:flutter_app/repositories/local_auth_repository.dart';
import 'package:flutter_app/repositories/mqtt_temperature_service.dart';
import 'package:flutter_app/widgets/profile_station_list.dart';
import 'package:flutter_app/widgets/profile_user_header.dart';
import 'package:flutter_app/widgets/station_editor_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _mqttServer = '10.156.119.71';
  static const _mqttWebSocketServer = 'ws://10.156.119.71';
  static const _mqttTopic = 'esp8266/temperature';

  final LocalAuthRepository _localRepo = LocalAuthRepository();
  final ApiAuthRepository _apiRepo = ApiAuthRepository();
  late final MqttTemperatureService _mqttService;

  User? _currentUser;
  double? _sensorTemperature;
  bool _mqttConnected = false;
  StreamSubscription<double?>? _temperatureSub;
  StreamSubscription<bool>? _connectionSub;

  @override
  void initState() {
    super.initState();
    _mqttService = MqttTemperatureService(
      server: _mqttServer,
      clientId: 'flutter_profile_${DateTime.now().millisecondsSinceEpoch}',
      topic: _mqttTopic,
      websocketServer: _mqttWebSocketServer,
    );

    _temperatureSub = _mqttService.temperatureStream.listen((value) {
      if (!mounted || value == null) return;
      setState(() => _sensorTemperature = value);
    });

    _connectionSub = _mqttService.connectionStream.listen((connected) {
      if (!mounted) return;
      setState(() => _mqttConnected = connected);
    });

    _loadUser();
    _mqttService.connect();
  }

  @override
  void dispose() {
    _temperatureSub?.cancel();
    _connectionSub?.cancel();
    _mqttService.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_session_user');

    if (!mounted) return;
    if (userJson == null) {
      setState(() => _currentUser = null);
      return;
    }

    setState(() {
      _currentUser = User.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
    });
  }

  Future<void> _saveData() async {
    final user = _currentUser;
    if (user == null) return;

    await _localRepo.updateUserData(user);
    try {
      await _apiRepo.syncStations(user);
    } catch (_) {
      // Local save already completed; sync will be retried next time.
    }
  }

  Future<void> _addStation() async {
    final user = _currentUser;
    if (user == null) return;

    final station = await showStationEditorDialog(context: context);
    if (station == null) return;

    setState(() => user.stations.add(station));
    await _saveData();
  }

  Future<void> _editStation(int index) async {
    final user = _currentUser;
    if (user == null) return;

    final station = await showStationEditorDialog(
      context: context,
      initialStation: user.stations[index],
    );
    if (station == null) return;

    setState(() => user.stations[index] = station);
    await _saveData();
  }

  Future<void> _deleteStation(int index) async {
    final user = _currentUser;
    if (user == null) return;

    setState(() => user.stations.removeAt(index));
    await _saveData();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Підтвердження виходу'),
        content: const Text('Ви дійсно хочете вийти з акаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Вийти'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    await _localRepo.clearSession();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Мій профіль')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProfileUserHeader(
              user: user,
              mqttConnected: _mqttConnected,
              sensorTemperature: _sensorTemperature,
            ),
            const Divider(height: 30),
            Expanded(
              child: ProfileStationList(
                stations: user.stations,
                onAdd: _addStation,
                onEdit: _editStation,
                onDelete: _deleteStation,
              ),
            ),
            TextButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Вийти', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
