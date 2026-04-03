import 'dart:convert';
import 'package:flutter_app/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthRepository {
  final String _usersListKey = 'all_users_list';
  final String _currentUserKey = 'current_session_user';

  // РЕЄСТРАЦІЯ
  Future<void> registerUser(User newUser) async {
    final prefs = await SharedPreferences.getInstance();
    final List<User> allUsers = await _getAllUsers();

    // Видаляємо дублікат за імейлом
    allUsers.removeWhere(
      (u) => u.email.trim().toLowerCase() == 
             newUser.email.trim().toLowerCase(),
    );

    allUsers.add(newUser);

    // Кодуємо список у JSON
    final String encodedList = jsonEncode(
      allUsers.map((u) => u.toJson()).toList(),
    );
    
    await prefs.setString(_usersListKey, encodedList);

    // Оновлюємо поточну сесію
    await prefs.setString(
      _currentUserKey, 
      jsonEncode(newUser.toJson()),
    );
  }

  // ЛОГІН
  Future<User?> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final List<User> allUsers = await _getAllUsers();

    try {
      final User foundUser = allUsers.firstWhere(
        (u) => u.email.trim().toLowerCase() == email.trim().toLowerCase() &&
               u.password.trim() == password.trim(),
      );

      await prefs.setString(
        _currentUserKey, 
        jsonEncode(foundUser.toJson()),
      );
      return foundUser;
    } catch (e) {
      return null;
    }
  }

  // ОТРИМАННЯ ВСІХ ЮЗЕРІВ
  Future<List<User>> _getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersJson = prefs.getString(_usersListKey);

    if (usersJson == null) return [];

    final decoded = jsonDecode(usersJson);
    final List<dynamic> decodedList = decoded as List<dynamic>;

    return decodedList
        .map((item) => User.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ОНОВЛЕННЯ ДАНИХ
  Future<void> updateUserData(User updatedUser) async {
    final prefs = await SharedPreferences.getInstance();

    await registerUser(updatedUser);
    await prefs.setString(
      _currentUserKey, 
      jsonEncode(updatedUser.toJson()),
    );
  }

  // ВИХІД
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
}
