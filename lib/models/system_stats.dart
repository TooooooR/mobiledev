class SystemStats {
  final double cpuLoad;      // %
  final double ramUsage;     // MB або %
  final double temperature;  // °C
  final String uptime;       // Формат "1d 5h 20m"

  const SystemStats({
    required this.cpuLoad,
    required this.ramUsage,
    required this.temperature,
    required this.uptime,
  });

  // Конвертація в Map для JSON
  Map<String, dynamic> toJson() => {
    'cpuLoad': cpuLoad,
    'ramUsage': ramUsage,
    'temperature': temperature,
    'uptime': uptime,
  };

  // Створення об'єкта з JSON
  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      cpuLoad: (json['cpuLoad'] as num).toDouble(),
      ramUsage: (json['ramUsage'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      uptime: json['uptime'].toString(),
    );
  }
}
