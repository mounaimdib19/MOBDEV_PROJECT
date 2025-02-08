import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';


class AssistanceRequestManager {
  static const String _lastRequestKey = 'last_assistance_request_time';

  static Future<bool> canMakeRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRequestTime = prefs.getInt(_lastRequestKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return currentTime - lastRequestTime >= 180000; // 3 minutes in milliseconds
  }

  static Future<void> updateLastRequestTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastRequestKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<Map<String, dynamic>> submitAssistanceRequest(String phoneNumber) async {
    if (!(await canMakeRequest())) {
      return {
        'success': false,
        'message': 'Please wait 3 minutes before submitting another request.',
      };
    }

    try {
      final response = await http.post(
        Uri.parse(Environment.submitAssistanceRequest),
        body: {
          'phone_number': phoneNumber,
        },
      );

      if (response.statusCode == 200) {
        final String responseBody = response.body.trim();
        if (responseBody.startsWith('{') && responseBody.endsWith('}')) {
          final result = json.decode(responseBody);
          if (result['success']) {
            await updateLastRequestTime();
          }
          return result;
        } else {
          throw FormatException('Invalid JSON response: $responseBody');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}');
      }
    } catch (e) {
      print('Error in submitAssistanceRequest: $e');
      return {
        'success': false,
        'message': 'Une erreur s est produite lors de l envoi de la demande. Veuillez réessayer ultérieurement.',
      };
    }
  }
}