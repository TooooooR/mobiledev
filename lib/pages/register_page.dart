import 'package:flutter/material.dart';

import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/models/system_stats.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/repositories/api_auth_repository.dart';
import 'package:flutter_app/repositories/i_auth_repository.dart';
import 'package:flutter_app/widgets/app_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final IAuthRepository _authRepo = ApiAuthRepository();

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final defaultStations = [
        Station(
          id: '1',
          name: 'Main Server',
          stats: const SystemStats(
            cpuLoad: 10,
            ramUsage: 2048,
            temperature: 40,
            uptime: '0h 0m',
          ),
        ),
      ];

      final newUser = User(
        name: _nameController.text,
        email: _emailController.text,
        password: _passController.text,
        stations: defaultStations,
      );

      await _authRepo.registerUser(newUser);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Реєстрація успішна!')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Реєстрація')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppInput(
                label: "Ім'я",
                icon: Icons.person,
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введіть ім\'я';
                  }
                  if (RegExp(r'[0-9]').hasMatch(value)) {
                    return 'Ім\'я не повинно містити цифр';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                label: 'Email',
                icon: Icons.email,
                controller: _emailController,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Введіть коректний Email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                label: 'Password',
                icon: Icons.lock,
                isPassword: true,
                controller: _passController,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Мінімум 6 символів';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Створити акаунт'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
