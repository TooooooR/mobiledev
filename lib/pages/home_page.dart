import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/widgets/build_stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  String? selectedStationId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // Завантажуємо дані один раз при старті
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('current_session_user');

    if (userJson != null) {
      final loadedUser = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      setState(() {
        user = loadedUser;
        // Вибираємо ID тільки якщо він ще не вибраний
        if (selectedStationId == null && loadedUser.stations.isNotEmpty) {
          selectedStationId = loadedUser.stations.first.id;
        }
        isLoading = false;
      });
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));
    }

    final stations = user!.stations;

    // Якщо станцій немає
    if (stations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('PCMonitor')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Немає станцій'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/profile');
                  _loadData(); // після повернення
                },
                child: const Text('Перейти в профіль'),
              ),
            ],
          ),
        ),
      );
    }

    // Знаходимо поточну станцію безпечно
    final currentStation = stations.firstWhere(
          (s) => s.id == selectedStationId,
      orElse: () => stations.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentStation.id,
            dropdownColor: Colors.grey[900],
            isDense: true, // Допомагає уникнути багів з висотою в AppBar
            icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
            items: stations.map((s) => DropdownMenuItem(
              value: s.id,
              child: Text(s.name, style: const TextStyle(color: Colors.white)),
            )).toList(),
            onChanged: (newId) {
              if (newId != null) {
                setState(() => selectedStationId = newId);
              }
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              // await чекає, поки ти закриєш профіль
              await Navigator.pushNamed(context, '/profile', arguments: user);
              _loadData(); // Оновлюємо дані, якщо в профілі щось змінили
            },
          ),
        ],
      ),
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