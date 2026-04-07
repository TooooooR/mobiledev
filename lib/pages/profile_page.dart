import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/models/system_stats.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/repositories/local_auth_repository.dart';
import 'package:flutter_app/repositories/mqtt_temperature_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _mqttServer = '10.156.119.71';
  static const String _mqttWebSocketServer = 'ws://10.156.119.71';
  static const String _mqttTopic = 'esp8266/temperature';

  User? currentUser;
  late final MqttTemperatureService _mqttService;

  double? _sensorTemperature;
  bool _mqttConnected = false;
  StreamSubscription<double?>? _temperatureSub;
  StreamSubscription<bool>? _connectionSub;

  final _nameController = TextEditingController();
  final _cpuController = TextEditingController();
  final _ramController = TextEditingController();
  final _tempController = TextEditingController();

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
    _nameController.dispose();
    _cpuController.dispose();
    _ramController.dispose();
    _tempController.dispose();
    _mqttService.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('current_session_user');

    if (json != null) {
      setState(() {
        currentUser = User.fromJson(jsonDecode(json) as Map<String, dynamic>);
      });
    }
  }

  Future<void> _saveData() async {
    if (currentUser == null) return;
    final authRepo = LocalAuthRepository();
    await authRepo.updateUserData(currentUser!);
  }

  void _clearControllers() {
    _nameController.clear();
    _cpuController.clear();
    _ramController.clear();
    _tempController.clear();
  }

  void _showEditStationDialog(int index) {
    final station = currentUser!.stations[index];
    final navigator = Navigator.of(context); // ЗАХИСТ

    _nameController.text = station.name;
    _cpuController.text = station.stats.cpuLoad.toString();
    _ramController.text = station.stats.ramUsage.toString();
    _tempController.text = station.stats.temperature.toString();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редагувати станцію'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Назва'),
              ),
              TextField(
                controller: _cpuController,
                decoration: const InputDecoration(labelText: 'CPU (%)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _ramController,
                decoration: const InputDecoration(labelText: 'RAM (MB)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _tempController,
                decoration: const InputDecoration(
                  labelText: 'Температура (°C)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearControllers();
            },
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                station.name = _nameController.text;
                station.stats = SystemStats(
                  cpuLoad: double.tryParse(_cpuController.text) ?? 0.0,
                  ramUsage: double.tryParse(_ramController.text) ?? 0.0,
                  temperature: double.tryParse(_tempController.text) ?? 0.0,
                  uptime: station.stats.uptime,
                );
              });
              await _saveData();
              if (mounted) {
                _clearControllers();
                navigator.pop();
              }
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

  void _showAddStationDialog() {
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Нова станція'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Назва'),
              ),
              TextField(
                controller: _cpuController,
                decoration: const InputDecoration(labelText: 'CPU (%)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _ramController,
                decoration: const InputDecoration(labelText: 'RAM (MB)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _tempController,
                decoration: const InputDecoration(
                  labelText: 'Температура (°C)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStation = Station(
                id: 'st_${DateTime.now().millisecondsSinceEpoch}',
                name: _nameController.text.isEmpty
                    ? 'PC-${Random().nextInt(100)}'
                    : _nameController.text,
                stats: SystemStats(
                  cpuLoad: double.tryParse(_cpuController.text) ?? 0.0,
                  ramUsage: double.tryParse(_ramController.text) ?? 0.0,
                  temperature: double.tryParse(_tempController.text) ?? 0.0,
                  uptime: '0h 0m',
                ),
              );
              setState(() => currentUser!.stations.add(newStation));
              await _saveData();
              if (mounted) {
                _clearControllers();
                navigator.pop();
              }
            },
            child: const Text('Додати'),
          ),
        ],
      ),
    );
  }

  void _deleteStation(int index) async {
    setState(() => currentUser!.stations.removeAt(index));
    await _saveData();
  }

  Future<void> _confirmLogout() async {
    final navigator = Navigator.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Підтвердження виходу'),
        content: const Text('Ви дійсно хочете вийти з акаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Вийти'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) {
      return;
    }

    final authRepo = LocalAuthRepository();
    await authRepo.clearSession();
    if (mounted) {
      navigator.pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мій профіль'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 10),
            Text(
              currentUser!.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              currentUser!.email, 
              style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _mqttConnected ? Icons.sensors : Icons.sensors_off,
                  size: 16,
                  color: _mqttConnected ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  !_mqttConnected
                      ? 'Немає з\'єднання з брокером'
                      : _sensorTemperature == null
                      ? 'Температура: очікуємо дані...'
                      : 'Температура: '
                          '${_sensorTemperature!.toStringAsFixed(1)} °C',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Мої станції:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
                  onPressed: _showAddStationDialog,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: currentUser!.stations.length,
                itemBuilder: (context, index) {
                  final station = currentUser!.stations[index];
                  return Card(
                    child: ListTile(
                      onTap: () => _showEditStationDialog(index),
                      leading: const Icon(
                        Icons.computer, 
                        color: Colors.cyanAccent),
                      title: Text(station.name),
                      subtitle: Text(
                        'CPU: ${station.stats.cpuLoad.toStringAsFixed(0)}%',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline, 
                          color: Colors.red),
                        onPressed: () => _deleteStation(index),
                      ),
                    ),
                  );
                },
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
