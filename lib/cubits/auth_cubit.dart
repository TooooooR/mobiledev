import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/models/system_stats.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/repositories/i_auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthStatus { idle, loading, success, failure }

enum AuthFlow { login, register, logout }

class AuthState {
  final AuthStatus status;
  final AuthFlow? flow;
  final User? user;
  final String? message;

  const AuthState({
    this.status = AuthStatus.idle,
    this.flow,
    this.user,
    this.message,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthFlow? flow,
    User? user,
    String? message,
    bool clearMessage = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      flow: flow ?? this.flow,
      user: clearUser ? null : user ?? this.user,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required IAuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState());

  final IAuthRepository _authRepository;

  Future<void> login({required String email, required String password}) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        flow: AuthFlow.login,
        clearMessage: true,
      ),
    );

    final user = await _authRepository.login(email, password);
    if (user == null) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          flow: AuthFlow.login,
          message: 'Невірний e-mail або пароль!',
          clearUser: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.success,
        flow: AuthFlow.login,
        user: user,
      ),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        flow: AuthFlow.register,
        clearMessage: true,
      ),
    );

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
      name: name,
      email: email,
      password: password,
      stations: defaultStations,
    );

    try {
      await _authRepository.registerUser(newUser);
      emit(
        state.copyWith(
          status: AuthStatus.success,
          flow: AuthFlow.register,
          user: newUser,
          message: 'Реєстрація успішна!',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          flow: AuthFlow.register,
          message: 'Не вдалося зареєструвати користувача.',
          clearUser: true,
        ),
      );
    }
  }

  Future<void> logout() async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        flow: AuthFlow.logout,
        clearMessage: true,
      ),
    );

    try {
      await _authRepository.clearSession();
      emit(
        state.copyWith(
          status: AuthStatus.success,
          flow: AuthFlow.logout,
          clearUser: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          flow: AuthFlow.logout,
          message: 'Не вдалося вийти з акаунта.',
        ),
      );
    }
  }
}
