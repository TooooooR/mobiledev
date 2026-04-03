class SystemStats {
  final double cpuLoad;
  final double ramUsage;  
  final double temperature; 
  final String uptime;     

  const SystemStats({
    required this.cpuLoad,
    required this.ramUsage,
    required this.temperature,
    required this.uptime,
  });

  Map<String, dynamic> toJson() => {
    'cpuLoad': cpuLoad,
    'ramUsage': ramUsage,
    'temperature': temperature,
    'uptime': uptime,
  };

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      cpuLoad: (json['cpuLoad'] as num).toDouble(),
      ramUsage: (json['ramUsage'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      uptime: json['uptime'].toString(),
    );
  }
}
