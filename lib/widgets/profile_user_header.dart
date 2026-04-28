import 'package:flutter/material.dart';
import 'package:flutter_app/models/user.dart';

class ProfileUserHeader extends StatelessWidget {
  final User user;
  final bool mqttConnected;
  final double? sensorTemperature;

  const ProfileUserHeader({
    required this.user,
    required this.mqttConnected,
    required this.sensorTemperature,
    super.key,
  });

  String _sensorText() {
    if (!mqttConnected) {
      return 'Немає з\'єднання з брокером';
    }
    if (sensorTemperature == null) {
      return 'Температура: очікуємо дані...';
    }
    return 'Температура: ${sensorTemperature!.toStringAsFixed(1)} °C';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
        const SizedBox(height: 10),
        Text(
          user.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(user.email, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mqttConnected ? Icons.sensors : Icons.sensors_off,
              size: 16,
              color: mqttConnected ? Colors.greenAccent : Colors.redAccent,
            ),
            const SizedBox(width: 6),
            Text(_sensorText(), style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }
}
