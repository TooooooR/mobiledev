import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/app_input.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monitor_heart, size: 80, color: Colors.cyanAccent),
            const Text('PCMonitor', style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            const AppInput(label: 'Email', icon: Icons.email),
            const SizedBox(height: 16),
            const AppInput(label:'Password',icon: Icons.lock, isPassword: true),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              child: const Text('Увійти'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Немає акаунту?  Реєстрація'),
            ),
          ],
        ),
      ),
    );
  }
}
