import 'package:flutter/material.dart';
import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/widgets/build_stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PCStation selectedStation = myStations[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<PCStation>(
            value: selectedStation,
            dropdownColor: Colors.grey[900],
            icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
            items: myStations.map((PCStation station) {
              return DropdownMenuItem<PCStation>(
                value: station,
                child: Row(
                  children: [
                    Icon(
                      station.type == 'Server' ? Icons.dns : Icons.computer,
                      size: 20,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(width: 10),
                    Text(station.name, style: const TextStyle(fontSize: 18)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (PCStation? newValue) {
              setState(() {
                selectedStation = newValue!;
              });
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                const BuildStatCard(
                  title: 'CPU Load', 
                  value: '45%', 
                  icon: Icons.speed, 
                  color: Colors.orange
                ),
                const BuildStatCard(
                  title: 'RAM', 
                  value: '8/16 GB', 
                  icon: Icons.memory, 
                  color: Colors.blue
                ),
                const BuildStatCard(
                  title: 'Temp', 
                  value: '52°C', 
                  icon: Icons.thermostat, 
                  color: Colors.red
                ),
                const BuildStatCard(
                  title: 'Uptime', 
                  value: '2h 15m', 
                  icon: Icons.timer, 
                  color: Colors.green
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
