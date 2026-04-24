import 'package:flutter/material.dart';
import 'package:flutter_app/models/station.dart';

class ProfileStationList extends StatelessWidget {
  final List<Station> stations;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  const ProfileStationList({
    required this.stations,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Мої станції:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
              onPressed: onAdd,
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              return Card(
                child: ListTile(
                  onTap: () => onEdit(index),
                  leading: const Icon(Icons.computer, color: Colors.cyanAccent),
                  title: Text(station.name),
                  subtitle: Text(
                    'CPU: ${station.stats.cpuLoad.toStringAsFixed(0)}%',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => onDelete(index),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
