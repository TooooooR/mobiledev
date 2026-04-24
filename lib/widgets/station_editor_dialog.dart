import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/models/system_stats.dart';

Future<Station?> showStationEditorDialog({
  required BuildContext context,
  Station? initialStation,
}) async {
  final nameController = TextEditingController(
    text: initialStation?.name ?? '',
  );
  final cpuController = TextEditingController(
    text: initialStation?.stats.cpuLoad.toString() ?? '',
  );
  final ramController = TextEditingController(
    text: initialStation?.stats.ramUsage.toString() ?? '',
  );
  final tempController = TextEditingController(
    text: initialStation?.stats.temperature.toString() ?? '',
  );

  final result = await showDialog<Station>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        initialStation == null ? 'Нова станція' : 'Редагувати станцію',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Назва'),
            ),
            TextField(
              controller: cpuController,
              decoration: const InputDecoration(labelText: 'CPU (%)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: ramController,
              decoration: const InputDecoration(labelText: 'RAM (MB)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: tempController,
              decoration: const InputDecoration(labelText: 'Температура (°C)'),
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
          onPressed: () {
            final station = Station(
              id:
                  initialStation?.id ??
                  'st_${DateTime.now().millisecondsSinceEpoch}',
              name: nameController.text.isEmpty
                  ? 'PC-${Random().nextInt(100)}'
                  : nameController.text,
              isOn: initialStation?.isOn ?? false,
              stats: SystemStats(
                cpuLoad: double.tryParse(cpuController.text) ?? 0,
                ramUsage: double.tryParse(ramController.text) ?? 0,
                temperature: double.tryParse(tempController.text) ?? 0,
                uptime: initialStation?.stats.uptime ?? '0h 0m',
              ),
            );
            Navigator.pop(context, station);
          },
          child: const Text('Зберегти'),
        ),
      ],
    ),
  );

  nameController.dispose();
  cpuController.dispose();
  ramController.dispose();
  tempController.dispose();

  return result;
}
