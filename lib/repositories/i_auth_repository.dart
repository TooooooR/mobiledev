import 'package:flutter_app/models/system_stats.dart';
import 'package:flutter_app/models/user.dart';

abstract class IAuthRepository {
  // Реєстрація: зберігає користувача в SharedPrefs
  Future<void> registerUser(User user);

  // Логін: перевіряє пошту та пароль
  Future<User?> login(String email, String password);

  // Оновлення даних станції
  Future<void> updateStationData(String stationId, SystemStats newStats);
  
  // Видалення даних (для Logout)
  Future<void> clearSession();
}
