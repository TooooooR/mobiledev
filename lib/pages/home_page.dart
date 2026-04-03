import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/widgets/build_stat_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedStationId;

  Future<User?> _loadUser(Object? args) async {
    if (args is User) return args;

    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('current_session_user');
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    return FutureBuilder<User?>(
      future: _loadUser(args),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent)
              ),
          );
        }

        final user = snapshot.data;

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
                  onPressed: () => Navigator.pushNamed(context, '/profile', arguments: user),
                ),
              ],
            ),
            body: const Center(
              child: Text('У вас ще немає станцій. Додайте їх у профілі.'),
            ),
          );
        }

        if (selectedStationId == null || !user.stations.any(
          (s) => s.id == selectedStationId)) {
          selectedStationId = user.stations.first.id;
        }

        final currentStation = user.stations.firstWhere(
          (s) => s.id == selectedStationId);

        return Scaffold(
          appBar: AppBar(
            title: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedStationId,
                dropdownColor: Colors.grey[900],
                icon: const Icon(
                  Icons.arrow_drop_down, 
                  color: Colors.cyanAccent
                  ),
                items: user.stations.map((Station station) {
                  return DropdownMenuItem<String>(
                    value: station.id,
                    child: Text(
                      station.name, 
                      style: const TextStyle(color: Colors.white)
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
                onPressed: () => Navigator.pushNamed(context, '/profile', arguments: user),
              ),
              const SizedBox(width: 8),
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
                value: '${
                  currentStation.stats.cpuLoad.toStringAsFixed(0)}%',
                icon: Icons.speed,
                color: Colors.orange,
              ),
              BuildStatCard(
                title: 'RAM',
                value: '${
                  currentStation.stats.ramUsage.toStringAsFixed(0)} MB',
                icon: Icons.memory,
                color: Colors.blue,
              ),
              BuildStatCard(
                title: 'Temp',
                value: '${
                  currentStation.stats.temperature.toStringAsFixed(0)}°C',
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
      },
    );
  }
}
