import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/repositories/network_status_service.dart';
import 'package:flutter_app/repositories/session_user_storage.dart';
import 'package:flutter_app/widgets/home_station_selector.dart';
import 'package:flutter_app/widgets/offline_status_bar.dart';
import 'package:flutter_app/widgets/station_stats_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NetworkStatusService _networkStatus = NetworkStatusService();
  final SessionUserStorage _sessionStorage = SessionUserStorage();

  StreamSubscription<bool>? _networkSubscription;
  User? _user;
  String? _selectedStationId;
  bool _isLoading = true;
  bool _isOnline = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _startNetworkMonitoring();
  }

  Future<void> _startNetworkMonitoring() async {
    _isOnline = await _networkStatus.isOnline();
    if (!mounted) return;
    setState(() {});

    _networkSubscription = _networkStatus.onStatusChanged.listen((isOnline) {
      if (!mounted) return;
      final wasOnline = _isOnline;
      setState(() => _isOnline = isOnline);

      if (wasOnline != isOnline) {
        final msg = isOnline
            ? 'Інтернет-з\'єднання відновлено.'
            : 'Інтернет-з\'єднання втрачено.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    });
  }

  Future<void> _initializeHomeData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final user = await _sessionStorage.loadUser(args);
    if (!mounted) return;

    setState(() {
      _user = user;
      if (user != null) {
        _selectedStationId = _sessionStorage.resolveSelectedStationId(
          user,
          _selectedStationId,
        );
      }
      _isLoading = false;
    });

    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Автовхід в офлайн-режимі.')),
      );
    }
  }

  Future<void> _openProfile() async {
    await Navigator.pushNamed(context, '/profile', arguments: _user);
    final refreshedUser = await _sessionStorage.loadUser(null);
    if (!mounted) return;

    setState(() {
      _user = refreshedUser;
      if (refreshedUser != null) {
        _selectedStationId = _sessionStorage.resolveSelectedStationId(
          refreshedUser,
          _selectedStationId,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;
    _initializeHomeData();
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    if (user == null) {
      final navigator = Navigator.of(context);
      Future.microtask(() => navigator.pushReplacementNamed('/login'));
      return const Scaffold();
    }

    final station = _sessionStorage.findSelectedStation(
      user,
      _selectedStationId,
    );

    return Scaffold(
      appBar: AppBar(
        title: HomeStationSelector(
          selectedStationId: _selectedStationId,
          stations: user.stations,
          onChanged: (id) => setState(() => _selectedStationId = id),
        ),
        actions: [
          IconButton(onPressed: _openProfile, icon: const Icon(Icons.person)),
        ],
      ),
      bottomNavigationBar: _isOnline ? null : const OfflineStatusBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: station == null
            ? const Center(
                child: Text('У вас ще немає станцій. Додайте їх у профілі.'),
              )
            : StationStatsGrid(station: station),
      ),
    );
  }
}
