import 'package:flutter/material.dart';
import 'package:flutter_app/pages/home_page.dart';
import 'package:flutter_app/pages/login_page.dart';
import 'package:flutter_app/pages/profile_page.dart';
import 'package:flutter_app/pages/register_page.dart';

void main() {
  runApp(const PCMonitor());
}

class PCMonitor extends StatelessWidget {
  const PCMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCMonitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
