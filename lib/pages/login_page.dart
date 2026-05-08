import 'package:flashlight_plugin/flashlight_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/cubits/auth_cubit.dart';
import 'package:flutter_app/widgets/app_input.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  void _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введіть email і пароль.')));
      return;
    }

    context.read<AuthCubit>().login(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );
  }

  Future<void> _toggleFlashlight() async {
    try {
      await FlashlightPlugin.onLight();
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status || previous.flow != current.flow,
      listener: (context, state) {
        if (state.flow != AuthFlow.login) return;

        if (state.status == AuthStatus.success) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }

        if (state.status == AuthStatus.failure) {
          final message = state.message ?? 'Помилка входу.';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monitor_heart,
                    size: 80,
                    color: Colors.cyanAccent,
                  ),
                  const Text(
                    'PCMonitor',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  AppInput(
                    label: 'Email',
                    icon: Icons.email,
                    controller: _emailController,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    label: 'Password',
                    icon: Icons.lock,
                    isPassword: true,
                    controller: _passController,
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading =
                          state.status == AuthStatus.loading &&
                              state.flow == AuthFlow.login;

                      return ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Увійти'),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text('Немає акаунту? Реєстрація'),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Opacity(
                opacity: 0.2,
                child: IconButton(
                  onPressed: _toggleFlashlight,
                  icon: const Icon(Icons.flash_on),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
