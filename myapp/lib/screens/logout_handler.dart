import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'login_screen.dart';
import '../config/environment.dart';
import '../cache_manager.dart';
import '../services/session_manager.dart';

class LogoutHandler {
  static Future<void> logout(BuildContext context) async {
    debugPrint('🔵 Starting logout process...');
    
    // Get Navigator state before showing overlay
    final navigator = Navigator.of(context);
    
    // Create loading overlay
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
      // Show loading overlay
      debugPrint('🔵 Showing loading overlay');
      overlayState.insert(loadingOverlay);

      // 1. First check current session
      debugPrint('🔵 Checking current session');
      final currentSession = await SessionManager.getSession();
      debugPrint('🔵 Current session state: $currentSession');

      // 2. Attempt server logout
      debugPrint('🔵 Attempting server logout');
      try {
        final response = await http.post(
          Uri.parse(Environment.logout),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        debugPrint('🔵 Server response: ${response.statusCode}');
        debugPrint('🔵 Response body: ${response.body}');
      } catch (e) {
        debugPrint('🔴 Server logout failed: $e');
        // Continue with local logout
      }

      // 3. Clear local session
      debugPrint('🔵 Clearing local session');
      await SessionManager.clearSession();
      debugPrint('🔵 Session cleared');

      // 4. Clear cache
      debugPrint('🔵 Clearing cache');
      CacheManager.clearCache(context);
      debugPrint('🔵 Cache cleared');

      // 5. Remove loading overlay
      debugPrint('🔵 Removing loading overlay');
      loadingOverlay.remove();

      // 6. Navigate to login screen using the stored navigator
      debugPrint('🔵 Navigating to login screen');
      await navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
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