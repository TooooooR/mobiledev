import 'package:flutter_app/models/system_stats.dart';

class Station {
  final String id;
  String name;        // Прибрали final
  bool isOn;          // Додали статус
  SystemStats stats;

  Station({
    required this.id,
    required this.name,
    required this.stats,
    this.isOn = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isOn': isOn,
    'stats': stats.toJson(),
  };

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      isOn: json['isOn'] as bool? ?? false,
      stats: SystemStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }
}