import 'dart:async';

import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/repositories/network_status_service.dart';
import 'package:flutter_app/repositories/session_user_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeState {
  final User? user;
  final String? selectedStationId;
  final Station? selectedStation;
  final bool isLoading;
  final bool isOnline;

  const HomeState({
    this.user,
    this.selectedStationId,
    this.selectedStation,
    this.isLoading = true,
    this.isOnline = true,
  });

  HomeState copyWith({
    User? user,
    String? selectedStationId,
    Station? selectedStation,
    bool? isLoading,
    bool? isOnline,
    bool clearUser = false,
    bool clearSelection = false,
  }) {
    return HomeState(
      user: clearUser ? null : user ?? this.user,
      selectedStationId:
          clearSelection ? null : selectedStationId ?? this.selectedStationId,
      selectedStation:
          clearSelection ? null : selectedStation ?? this.selectedStation,
      isLoading: isLoading ?? this.isLoading,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required NetworkStatusService networkStatus,
    required SessionUserStorage sessionUserStorage,
  })  : _networkStatus = networkStatus,
        _sessionStorage = sessionUserStorage,
        super(const HomeState());

  final NetworkStatusService _networkStatus;
  final SessionUserStorage _sessionStorage;
  StreamSubscription<bool>? _networkSubscription;
  bool _initialized = false;

  Future<void> initialize(Object? args) async {
    if (_initialized) return;
    _initialized = true;
    await _startNetworkMonitoring();
    await _loadUser(args);
  }

  Future<void> refreshUser() async {
    await _loadUser(null);
  }

  void selectStation(String? stationId) {
    final user = state.user;
    if (user == null) return;

    final resolvedId =
        _sessionStorage.resolveSelectedStationId(user, stationId);
    final station = _sessionStorage.findSelectedStation(user, resolvedId);

    emit(
      state.copyWith(
        selectedStationId: resolvedId,
        selectedStation: station,
      ),
    );
  }

  Future<void> _startNetworkMonitoring() async {
    final isOnline = await _networkStatus.isOnline();
    emit(state.copyWith(isOnline: isOnline));

    _networkSubscription?.cancel();
    _networkSubscription = _networkStatus.onStatusChanged.listen((isOnline) {
      emit(state.copyWith(isOnline: isOnline));
    });
  }

  Future<void> _loadUser(Object? args) async {
    emit(state.copyWith(isLoading: true));
    final user = await _sessionStorage.loadUser(args);
    if (user == null) {
      emit(
        state.copyWith(
          isLoading: false,
          clearUser: true,
          clearSelection: true,
        ),
      );
      return;
    }

    final selectedStationId =
        _sessionStorage.resolveSelectedStationId(user, state.selectedStationId);
    final station = _sessionStorage.findSelectedStation(
      user,
      selectedStationId,
    );

    emit(
      state.copyWith(
        isLoading: false,
        user: user,
        selectedStationId: selectedStationId,
        selectedStation: station,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _networkSubscription?.cancel();
    return super.close();
  }
}
