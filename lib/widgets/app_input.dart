import 'package:flutter/material.dart';

class AppInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPassword;

  const AppInput({ 
    required this.label, 
    required this.icon, 
    this.isPassword = false,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
