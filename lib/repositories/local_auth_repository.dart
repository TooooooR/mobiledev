import 'dart:convert';

import 'package:flutter_app/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthRepository {
  final String _usersListKey = 'all_users_list'; // Список всіх профілів
  final String _currentUserKey = 'current_session_user'; // Поточна сесія

  // РЕЄСТРАЦІЯ (зберігаємо в список, щоб не затирати інших)
  Future<void> registerUser(User newUser) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Отримуємо список всіх існуючих юзерів
    final List<User> allUsers = await _getAllUsers();

    // 2. Видаляємо старого юзера з такою ж поштою (якщо є), щоб оновити дані
    allUsers.removeWhere((u) => u.email.trim().toLowerCase() == newUser.email.trim().toLowerCase());

    // 3. Додаємо нового
    allUsers.add(newUser);

    // 4. Зберігаємо весь список назад
    final String encodedList = jsonEncode(allUsers.map((u) => u.toJson()).toList());
    await prefs.setString(_usersListKey, encodedList);

    // 5. Автоматично робимо цього юзера "поточним" (сесія)
    await prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));
  }

  // ЛОГІН (шукаємо в списку)
  Future<User?> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<User> allUsers = await _getAllUsers();

    try {
      // Шукаємо юзера з чистою поштою та паролем
      final User foundUser = allUsers.firstWhere(
              (u) => u.email.trim().toLowerCase() == email.trim().toLowerCase() &&
              u.password.trim() == password.trim()
      );

      // Якщо знайшли — записуємо в активну сесію
      await prefs.setString(_currentUserKey, jsonEncode(foundUser.toJson()));
      return foundUser;
    } catch (e) {
      return null; // Юзера не знайдено
    }
  }

  // Допоміжний метод для отримання списку всіх користувачів
  Future<List<User>> _getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersJson = prefs.getString(_usersListKey);

    if (usersJson == null) return [];

    // 1. Декодуємо JSON (отримуємо dynamic)
    final decoded = jsonDecode(usersJson);

    // 2. Явно кажемо, що це список dynamic: as List<dynamic>
    final List<dynamic> decodedList = decoded as List<dynamic>;

    // 3. Перетворюємо кожен елемент списку на об'єкт User
    return decodedList.map((item) => User.fromJson(item as Map<String, dynamic>)).toList();
  }

  // ОНОВЛЕННЯ ДАНИХ (для Home та Profile)
  Future<void> updateUserData(User updatedUser) async {
    final prefs = await SharedPreferences.getInstance();

    // Оновлюємо і в загальному списку, і в поточній сесії
    await registerUser(updatedUser);
    await prefs.setString(_currentUserKey, jsonEncode(updatedUser.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey); // Видаляємо тільки сесію, а не юзера!
  }
}