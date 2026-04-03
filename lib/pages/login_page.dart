import 'package:flutter/material.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/repositories/local_auth_repository.dart';
import 'package:flutter_app/widgets/app_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _authRepo = LocalAuthRepository();

  void _handleLogin() async {
    final User? user = await _authRepo.login(
      _emailController.text, 
      _passController.text
    );

    if (user != null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
              (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Невірний e-mail або пароль!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monitor_heart, size: 80, color: Colors.cyanAccent),
            const Text(
              'PCMonitor', 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)
              ),
            const SizedBox(height: 40),
            AppInput(
              label: 'Email', 
              icon: Icons.email, 
              controller: _emailController
              ),
            const SizedBox(height: 16),
            AppInput(
              label: 'Password', 
              icon: Icons.lock, 
              isPassword: true, 
              controller: _passController
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleLogin,
              child: const Text('Увійти'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Немає акаунту? Реєстрація'),
            ),
          ],
        ),
      ),
    );
  }
}
