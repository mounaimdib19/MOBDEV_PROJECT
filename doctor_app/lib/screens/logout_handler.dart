import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'doctor_login_screen.dart';
import '../config/environment.dart';
import '../services/cache_manager.dart';
import '../services/session_manager.dart';
import '../services/location_service.dart';

class LogoutHandler {
  static Future<void> logout(BuildContext context) async {
    debugPrint('🔵 Starting doctor logout process...');
    
    final navigator = Navigator.of(context);
    final overlayState = Overlay.of(context);
    late OverlayEntry loadingOverlay;
    
    loadingOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );

    try {
      debugPrint('🔵 Showing loading overlay');
      overlayState.insert(loadingOverlay);

      // 1. Get doctor ID before clearing session
      debugPrint('🔵 Getting doctor ID');
      final doctorId = await SessionManager.getDoctorId();

      // 2. Stop location tracking
      if (doctorId != null) {
        debugPrint('🔵 Stopping location tracking');
        await LocationService.stopLocationTracking();
      }

      // 3. Attempt server logout
      debugPrint('🔵 Attempting server logout');
      try {
        final response = await http.post(
          Uri.parse(Environment.logout),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'id_doc': doctorId,
          }),
        ).timeout(const Duration(seconds: 10));

        debugPrint('🔵 Server response: ${response.statusCode}');
        debugPrint('🔵 Response body: ${response.body}');
      } catch (e) {
        debugPrint('🔴 Server logout failed: $e');
        // Continue with local logout
      }

      // 4. Clear local session
      debugPrint('🔵 Clearing local session');
      await SessionManager.clearSession();
      debugPrint('🔵 Session cleared');

      // 5. Clear cache
      debugPrint('🔵 Clearing cache');
      CacheManager.clearCache(context);
      debugPrint('🔵 Cache cleared');

      // 6. Remove loading overlay
      debugPrint('🔵 Removing loading overlay');
      loadingOverlay.remove();

      // 7. Navigate to login screen
      debugPrint('🔵 Navigating to login screen');
      await navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DoctorLoginScreen()),
        (Route<dynamic> route) => false,
      );
      debugPrint('🔵 Navigation complete');

    } catch (e) {
      debugPrint('🔴 Critical error during logout: $e');
      
      // Ensure overlay is removed
      loadingOverlay.remove();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}