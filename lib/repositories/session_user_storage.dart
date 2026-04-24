import 'dart:convert';

import 'package:flutter_app/models/station.dart';
import 'package:flutter_app/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionUserStorage {
  Future<User?> loadUser(Object? args) async {
    if (args is User) return args;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_session_user');
    if (userJson == null) return null;

    return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }

  String? resolveSelectedStationId(User user, String? selectedStationId) {
    if (user.stations.isEmpty) return null;

    final exists = user.stations.any(
      (station) => station.id == selectedStationId,
    );
    if (selectedStationId == null || !exists) {
      return user.stations.first.id;
    }
    return selectedStationId;
  }

  Station? findSelectedStation(User user, String? selectedStationId) {
    if (user.stations.isEmpty) return null;

    for (final station in user.stations) {
      if (station.id == selectedStationId) {
        return station;
      }
    }
    return user.stations.first;
  }
}
