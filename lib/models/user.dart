import 'package:flutter_app/models/station.dart';

class User {
  final String name;
  final String email;
  final String password;
  final List<Station> stations;

  const User({
    required this.name,
    required this.email,
    required this.password,
    required this.stations,
  });

  User copyWith({
    String? name,
    String? email,
    String? password,
    List<Station>? stations,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      stations: stations ?? this.stations,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'stations': stations.map((s) => s.toJson()).toList(),
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      stations: (json['stations'] as List<dynamic>)
          .map((s) => Station.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
