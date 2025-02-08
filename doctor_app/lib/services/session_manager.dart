import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyDoctorId = 'doctorId';
  static const String keyDoctorEmail = 'doctorEmail';

  // Store session data
  static Future<void> createSession(String doctorId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, true);
    await prefs.setString(keyDoctorId, doctorId);
    await prefs.setString(keyDoctorEmail, email);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }

  // Get stored doctor ID
  static Future<String?> getDoctorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyDoctorId);
  }

  // Clear session data
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}