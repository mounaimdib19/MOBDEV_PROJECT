import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SessionManager {
  static const String PHONE_KEY = 'phone_number';
  static const String PATIENT_ID_KEY = 'patient_id';
  
  static Future<void> saveSession(String phone, int patientId) async {
    debugPrint('🔵 Saving session for patient ID: $patientId');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PHONE_KEY, phone);
    await prefs.setInt(PATIENT_ID_KEY, patientId);
    debugPrint('🔵 Session saved successfully');
  }
  
  static Future<Map<String, dynamic>?> getSession() async {
    debugPrint('🔵 Getting session data');
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(PHONE_KEY);
    final patientId = prefs.getInt(PATIENT_ID_KEY);
    
    debugPrint('🔵 Current session - Phone: $phone, PatientID: $patientId');
    
    if (phone != null && patientId != null) {
      return {
        'phone': phone,
        'patientId': patientId,
      };
    }
    return null;
  }
  
  static Future<void> clearSession() async {
    try {
      debugPrint('🔵 Starting session clear');
      final prefs = await SharedPreferences.getInstance();
      
      // Check what we're clearing
      final phoneBeforeClear = prefs.getString(PHONE_KEY);
      final patientIdBeforeClear = prefs.getInt(PATIENT_ID_KEY);
      debugPrint('🔵 Current values before clear - Phone: $phoneBeforeClear, PatientID: $patientIdBeforeClear');
      
      await prefs.remove(PHONE_KEY);
      await prefs.remove(PATIENT_ID_KEY);
      
      // Verify clear was successful
      final phoneAfterClear = prefs.getString(PHONE_KEY);
      final patientIdAfterClear = prefs.getInt(PATIENT_ID_KEY);
      debugPrint('🔵 Values after clear - Phone: $phoneAfterClear, PatientID: $patientIdAfterClear');
      
      if (phoneAfterClear == null && patientIdAfterClear == null) {
        debugPrint('🔵 Session cleared successfully');
      } else {
        debugPrint('🔴 Warning: Some session data may not have been cleared');
      }
    } catch (e) {
      debugPrint('🔴 Error clearing session: $e');
      throw Exception('Failed to clear session: $e');
    }
  }
}