import 'package:flutter/material.dart';
import 'package:flutter_app/models/station.dart';

class HomeStationSelector extends StatelessWidget {
  final String? selectedStationId;
  final List<Station> stations;
  final ValueChanged<String?> onChanged;

  const HomeStationSelector({
    required this.selectedStationId,
    required this.stations,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return const Text('PCMonitor');
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedStationId,
        dropdownColor: Colors.grey[900],
        items: stations
            .map(
              (station) => DropdownMenuItem<String>(
                value: station.id,
                child: Text(station.name),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
