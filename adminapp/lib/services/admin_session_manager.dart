import 'package:shared_preferences/shared_preferences.dart';

class AdminSessionManager {
  static const String keyIsLoggedIn = 'admin_isLoggedIn';
  static const String keyAdminId = 'adminId';
  static const String keyAdminEmail = 'adminEmail';

  // Store session data with integer admin ID
  static Future<void> createSession(int adminId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, true);
    await prefs.setInt(keyAdminId, adminId);  // Changed to setInt
    await prefs.setString(keyAdminEmail, email);
  }
 
  // Check if admin is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }

  // Get stored admin ID as integer
  static Future<int?> getAdminId() async {  // Changed return type to int?
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyAdminId);  // Changed to getInt
  }
static Future<bool> isSessionValid() async {
    final loggedInStatus = await AdminSessionManager.isLoggedIn();
    final adminId = await AdminSessionManager.getAdminId();
    return loggedInStatus && adminId != null;
}
  // Clear session data
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}