import 'package:flutter_app/models/user.dart';

abstract class IAuthRepository {
  // Реєстрація: зберігає користувача в SharedPrefs
  Future<void> registerUser(User user);

  // Логін: перевіряє пошту та пароль
  Future<User?> login(String email, String password);
  
  // Видалення даних (для Logout)
  Future<void> clearSession();
}
