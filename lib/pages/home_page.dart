import 'package:flutter/material.dart';
import 'package:flutter_app/cubits/home_cubit.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/widgets/home_station_selector.dart';
import 'package:flutter_app/widgets/offline_status_bar.dart';
import 'package:flutter_app/widgets/station_stats_grid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openProfile(BuildContext context, User user) async {
    await Navigator.pushNamed(context, '/profile', arguments: user);
    if (!context.mounted) return;
    await context.read<HomeCubit>().refreshUser();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (previous, current) =>
              previous.isOnline != current.isOnline,
          listener: (context, state) {
            final msg = state.isOnline
                ? 'Інтернет-з\'єднання відновлено.'
                : 'Інтернет-з\'єднання втрачено.';
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          },
        ),
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (previous, current) =>
              previous.isLoading && !current.isLoading,
          listener: (context, state) {
            if (!state.isOnline) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Автовхід в офлайн-режимі.')),
              );
            }
          },
        ),
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (previous, current) =>
              previous.user != current.user ||
              previous.isLoading != current.isLoading,
          listener: (context, state) {
            if (!state.isLoading && state.user == null) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
      ],
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = state.user;
          if (user == null) {
            return const Scaffold();
          }

          final station = state.selectedStation;

          return Scaffold(
            appBar: AppBar(
              title: HomeStationSelector(
                selectedStationId: state.selectedStationId,
                stations: user.stations,
                onChanged: (id) =>
                    context.read<HomeCubit>().selectStation(id),
              ),
              actions: [
                IconButton(
                  onPressed: () => _openProfile(context, user),
                  icon: const Icon(Icons.person),
                ),
              ],
            ),
            bottomNavigationBar:
                state.isOnline ? null : const OfflineStatusBar(),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: station == null
                  ? const Center(
                      child:
                          Text('У вас ще немає станцій. Додайте їх у профілі.'),
                    )
                  : StationStatsGrid(station: station),
            ),
          );
        },
      ),
    );
  }
}
