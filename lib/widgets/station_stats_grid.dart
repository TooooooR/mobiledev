import 'package:flutter/material.dart';
import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/widgets/build_stat_card.dart';

class StationStatsGrid extends StatelessWidget {
  final Station station;

  const StationStatsGrid({required this.station, super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        BuildStatCard(
          title: 'CPU Load',
          value: '${station.stats.cpuLoad.toStringAsFixed(0)}%',
          icon: Icons.speed,
          color: Colors.orange,
        ),
        BuildStatCard(
          title: 'RAM',
          value: '${station.stats.ramUsage.toStringAsFixed(0)} MB',
          icon: Icons.memory,
          color: Colors.blue,
        ),
        BuildStatCard(
          title: 'Temp',
          value: '${station.stats.temperature.toStringAsFixed(0)}°C',
          icon: Icons.thermostat,
          color: Colors.red,
        ),
        BuildStatCard(
          title: 'Uptime',
          value: station.stats.uptime,
          icon: Icons.timer,
          color: Colors.green,
        ),
      ],
    );
  }
}
