import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/repositories/network_status_service.dart';
import 'package:flutter_app/widgets/build_stat_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedStationId;
  User? _user;
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _isOnline = true;
  bool _offlineAutoLoginWarningShown = false;

  final NetworkStatusService _networkStatus = NetworkStatusService();
  StreamSubscription<bool>? _networkSubscription;

  @override
  void initState() {
    super.initState();
    _startNetworkMonitoring();
  }

  Future<void> _startNetworkMonitoring() async {
    final initialOnline = await _networkStatus.isOnline();
    if (!mounted) return;

    setState(() {
      _isOnline = initialOnline;
    });

    _networkSubscription = _networkStatus.onStatusChanged.listen((isOnline) {
      if (!mounted) return;

      final wasOnline = _isOnline;
      setState(() {
        _isOnline = isOnline;
      });

      if (wasOnline && !isOnline) {
        _showConnectivityMessage('Інтернет-з\'єднання втрачено.');
      } else if (!wasOnline && isOnline) {
        _showConnectivityMessage('Інтернет-з\'єднання відновлено.');
      }
    });
  }

  void _showConnectivityMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildOfflineBar() {
    return Container(
      color: Colors.red.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Офлайн режим: перевірте Інтернет-з\'єднання',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<User?> _loadUser(Object? args) async {
    if (args is User) return args;

    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('current_session_user');
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    return null;
  }

  void _syncSelectedStation(User user) {
    if (user.stations.isEmpty) {
      selectedStationId = null;
      return;
    }

    if (selectedStationId == null ||
        !user.stations.any((s) => s.id == selectedStationId)) {
      selectedStationId = user.stations.first.id;
    }
  }

  Future<void> _initializeHomeData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final user = await _loadUser(args);
    if (!mounted) return;

    setState(() {
      _user = user;
      if (user != null) {
        _syncSelectedStation(user);
      }
      _isLoading = false;
    });

    final isOnlineNow = await _networkStatus.isOnline();
    if (!mounted) return;

    if (_isOnline != isOnlineNow) {
      setState(() {
        _isOnline = isOnlineNow;
      });
    }

    if (!isOnlineNow && !_offlineAutoLoginWarningShown) {
      _offlineAutoLoginWarningShown = true;
      _showConnectivityMessage(
        'Автовхід виконано без Інтернету. '
        'Деякі функції можуть бути недоступні.',
      );
    }
  }

  Future<void> _refreshUserFromStorage() async {
    final user = await _loadUser(null);
    if (!mounted) return;

    setState(() {
      _user = user;
      if (user != null) {
        _syncSelectedStation(user);
      }
    });
  }

  Future<void> _openProfile() async {
    await Navigator.pushNamed(context, '/profile', arguments: _user);
    if (!mounted) return;
    await _refreshUserFromStorage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;
    _initializeHomeData();
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    final user = _user;

    if (user == null) {
      final navigator = Navigator.of(context);

      Future.microtask(() {
        if (mounted) {
          navigator.pushReplacementNamed('/login');
        }
      });
      return const Scaffold();
    }

    if (user.stations.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PCMonitor'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: _openProfile,
            ),
          ],
        ),
        bottomNavigationBar: _isOnline ? null : _buildOfflineBar(),
        body: const Center(
          child: Text('У вас ще немає станцій. Додайте їх у профілі.'),
        ),
      );
    }

    final currentStation = user.stations.firstWhere(
      (s) => s.id == selectedStationId,
    );

    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedStationId,
            dropdownColor: Colors.grey[900],
            icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
            items: user.stations.map((Station station) {
              return DropdownMenuItem<String>(
                value: station.id,
                child: Text(
                  station.name,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (String? newId) {
              setState(() {
                selectedStationId = newId;
              });
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _openProfile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _isOnline ? null : _buildOfflineBar(),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          BuildStatCard(
            title: 'CPU Load',
            value: '${currentStation.stats.cpuLoad.toStringAsFixed(0)}%',
            icon: Icons.speed,
            color: Colors.orange,
          ),
          BuildStatCard(
            title: 'RAM',
            value: '${currentStation.stats.ramUsage.toStringAsFixed(0)} MB',
            icon: Icons.memory,
            color: Colors.blue,
          ),
          BuildStatCard(
            title: 'Temp',
            value: '${currentStation.stats.temperature.toStringAsFixed(0)}°C',
            icon: Icons.thermostat,
            color: Colors.red,
          ),
          BuildStatCard(
            title: 'Uptime',
            value: currentStation.stats.uptime,
            icon: Icons.timer,
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}
