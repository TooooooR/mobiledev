class PCStation {
  final String name;
  final String type; // наприклад, "Server", "Desktop", "Laptop"
  final bool isOnline;

  PCStation({required this.name, required this.type, this.isOnline = true});
}

// Твій список станцій
final List<PCStation> myStations = [
  PCStation(name: 'Home-PC', type: 'Desktop'),
  PCStation(name: 'Office-Server', type: 'Server'),
  PCStation(name: 'Home-Server', type: 'Server', isOnline: false),
];
