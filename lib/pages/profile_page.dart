import 'package:flutter/material.dart';
import 'package:flutter_app/models/station.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мій профіль')),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 20),
            const Text(
              'Taras Protsiv', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Group IR-31'),
            const Spacer(),
            FloatingActionButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Icon(Icons.logout, color: Colors.red), 
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Мої станції:', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myStations.length,
              itemBuilder: (context, index) {
                final station = myStations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      station.type == 'Server' ? Icons.dns : Icons.computer,
                      color: Colors.cyanAccent,
                    ),
                    title: Text(station.name),
                    subtitle: Text('Тип: ${station.type}'),
                    trailing: Icon(
                      Icons.circle, 
                      size: 12, 
                      color: station.isOnline ? Colors.green : Colors.red
                      ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
