import 'dart:async';

import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/repositories/api_auth_repository.dart';
import 'package:flutter_app/repositories/local_auth_repository.dart';
import 'package:flutter_app/repositories/mqtt_temperature_service.dart';
import 'package:flutter_app/repositories/session_user_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ProfileStatus { loading, idle, saving, failure }

class ProfileState {
  final ProfileStatus status;
  final User? user;
  final double? sensorTemperature;
  final bool mqttConnected;
  final String? message;

  const ProfileState({
    this.status = ProfileStatus.loading,
    this.user,
    this.sensorTemperature,
    this.mqttConnected = false,
    this.message,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    User? user,
    double? sensorTemperature,
    bool? mqttConnected,
    String? message,
    bool clearUser = false,
    bool clearMessage = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      sensorTemperature: sensorTemperature ?? this.sensorTemperature,
      mqttConnected: mqttConnected ?? this.mqttConnected,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required LocalAuthRepository localAuthRepository,
    required ApiAuthRepository apiAuthRepository,
    required SessionUserStorage sessionUserStorage,
    required MqttTemperatureService mqttService,
  })  : _localRepo = localAuthRepository,
        _apiRepo = apiAuthRepository,
        _sessionStorage = sessionUserStorage,
        _mqttService = mqttService,
        super(const ProfileState());

  final LocalAuthRepository _localRepo;
  final ApiAuthRepository _apiRepo;
  final SessionUserStorage _sessionStorage;
  final MqttTemperatureService _mqttService;

  StreamSubscription<double?>? _temperatureSub;
  StreamSubscription<bool>? _connectionSub;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _listenToMqtt();
    await _loadUser();
  }

  Future<void> addStation(Station station) async {
    final user = state.user;
    if (user == null) return;

    final updated = user.copyWith(stations: [...user.stations, station]);
    emit(state.copyWith(user: updated));
    await _persistUser(updated);
  }

  Future<void> updateStation(int index, Station station) async {
    final user = state.user;
    if (user == null) return;

    final updatedStations = [...user.stations];
    if (index < 0 || index >= updatedStations.length) return;

    updatedStations[index] = station;
    final updatedUser = user.copyWith(stations: updatedStations);

    emit(state.copyWith(user: updatedUser));
    await _persistUser(updatedUser);
  }

  Future<void> deleteStation(int index) async {
    final user = state.user;
    if (user == null) return;

    final updatedStations = [...user.stations];
    if (index < 0 || index >= updatedStations.length) return;

    updatedStations.removeAt(index);
    final updatedUser = user.copyWith(stations: updatedStations);

    emit(state.copyWith(user: updatedUser));
    await _persistUser(updatedUser);
  }

  Future<void> logout() async {
    emit(state.copyWith(status: ProfileStatus.saving, clearMessage: true));
    try {
      await _apiRepo.clearSession();
      emit(
        state.copyWith(
          status: ProfileStatus.idle,
          clearUser: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          message: 'Не вдалося вийти з акаунта.',
        ),
      );
    }
  }

  Future<void> _loadUser() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final user = await _sessionStorage.loadUser(null);
    emit(state.copyWith(status: ProfileStatus.idle, user: user));
  }

  void _listenToMqtt() {
    _temperatureSub?.cancel();
    _connectionSub?.cancel();

    _temperatureSub = _mqttService.temperatureStream.listen((value) {
      emit(state.copyWith(sensorTemperature: value));
    });

    _connectionSub = _mqttService.connectionStream.listen((connected) {
      emit(state.copyWith(mqttConnected: connected));
    });

    _mqttService.connect();
  }

  Future<void> _persistUser(User user) async {
    emit(state.copyWith(status: ProfileStatus.saving, clearMessage: true));
    try {
      await _localRepo.updateUserData(user);
      try {
        await _apiRepo.syncStations(user);
      } catch (_) {
        // Local save already completed; sync will be retried next time.
      }
      emit(state.copyWith(status: ProfileStatus.idle));
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          message: 'Не вдалося зберегти зміни.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _temperatureSub?.cancel();
    await _connectionSub?.cancel();
    _mqttService.disconnect();
    return super.close();
  }
}
