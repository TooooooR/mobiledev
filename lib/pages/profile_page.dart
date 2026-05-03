import 'package:flutter/material.dart';
import 'package:flutter_app/cubits/profile_cubit.dart';
import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/widgets/profile_station_list.dart';
import 'package:flutter_app/widgets/profile_user_header.dart';
import 'package:flutter_app/widgets/station_editor_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _addStation(BuildContext context) async {
    final station = await showStationEditorDialog(context: context);
    if (!context.mounted) return;
    if (station == null) return;

    await context.read<ProfileCubit>().addStation(station);
  }

  Future<void> _editStation(
    BuildContext context,
    Station station,
    int index,
  ) async {
    final updated = await showStationEditorDialog(
      context: context,
      initialStation: station,
    );
    if (!context.mounted) return;
    if (updated == null) return;

    await context.read<ProfileCubit>().updateStation(index, updated);
  }

  void _deleteStation(BuildContext context, int index) {
    context.read<ProfileCubit>().deleteStation(index);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Підтвердження виходу'),
        content: const Text('Ви дійсно хочете вийти з акаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Вийти'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (shouldLogout != true) return;
    await context.read<ProfileCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) =>
          previous.user != current.user || previous.status != current.status,
      listener: (context, state) {
        if (state.status == ProfileStatus.failure && state.message != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message!)));
        }

        if (state.user == null && state.status != ProfileStatus.loading) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Мій профіль')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ProfileUserHeader(
                    user: user,
                    mqttConnected: state.mqttConnected,
                    sensorTemperature: state.sensorTemperature,
                  ),
                  const Divider(height: 30),
                  Expanded(
                    child: ProfileStationList(
                      stations: user.stations,
                      onAdd: () => _addStation(context),
                      onEdit: (index) => _editStation(
                        context,
                        user.stations[index],
                        index,
                      ),
                      onDelete: (index) => _deleteStation(context, index),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Вийти',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
