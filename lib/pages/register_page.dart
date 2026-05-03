import 'package:flutter/material.dart';
import 'package:flutter_app/cubits/auth_cubit.dart';
import 'package:flutter_app/widgets/app_input.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  void _register() async {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passController.text.trim(),
          );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        if (state.flow != AuthFlow.register) return;

        if (state.status == AuthStatus.success) {
          final message = state.message ?? 'Реєстрація успішна!';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
          Navigator.pop(context);
        }

        if (state.status == AuthStatus.failure) {
          final message = state.message ?? 'Не вдалося створити акаунт.';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      },
      child: Scaffold(
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
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final isLoading =
                        state.status == AuthStatus.loading &&
                            state.flow == AuthFlow.register;

                    return ElevatedButton(
                      onPressed: isLoading ? null : _register,
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Створити акаунт'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
