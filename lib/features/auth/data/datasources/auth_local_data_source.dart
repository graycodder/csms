import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> saveUserSession(String userId);
  Future<String?> getUserSession();
  Future<void> clearUserSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  static const String _userIdKey = 'cached_user_id';

  @override
  Future<void> saveUserSession(String userId) async {
    await sharedPreferences.setString(_userIdKey, userId);
  }

  @override
  Future<String?> getUserSession() async {
    return sharedPreferences.getString(_userIdKey);
  }

  @override
  Future<void> clearUserSession() async {
    await sharedPreferences.remove(_userIdKey);
  }
}
