import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/app_input.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Реєстрація')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const AppInput(label: "Ім'я", icon: Icons.person),
            const SizedBox(height: 16),
            const AppInput(label: 'Email', icon: Icons.email),
            const SizedBox(height: 16),
            const AppInput(
              label: 'Password', 
              icon: Icons.lock, 
              isPassword: true
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Створити акаунт'),
            ),
          ],
        ),
      ),
    );
  }
}
