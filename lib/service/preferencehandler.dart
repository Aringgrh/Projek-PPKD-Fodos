import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  static late SharedPreferences _prefs;
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _keyIsLogin = "isLogin";
  static const _keyUserEmail = "userEmail";
  static const _keyUserProfileImage = "userProfileImage";

  static Future<void> setLogin(bool isLogin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLogin, isLogin);
  }

  static Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  static String? getUserEmail() {
    try {
      return _prefs.getString(_keyUserEmail);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setUserProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserProfileImage, path);
  }

  static String? getUserProfileImage() {
    try {
      return _prefs.getString(_keyUserProfileImage);
    } catch (_) {
      return null;
    }
  }

  static bool get isLogin {
    try {
      return _prefs.getBool(_keyIsLogin) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLogin);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserProfileImage);
  }
}
