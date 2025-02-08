import 'dart:convert';
import 'package:http/http.dart' as http;


class DetailedErrorLogger {
  /// Log detailed information about an API request and response
  static Future<void> logApiRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? requestBody,
    Map<String, String>? headers,
  }) async {
    print('===== DETAILED API REQUEST LOGGING =====');
    print('Endpoint: $endpoint');
    print('Method: $method');
    
    // Log request body details
    if (requestBody != null) {
      print('\n--- Request Body Details ---');
      requestBody.forEach((key, value) {
        print('$key: ${value.runtimeType} = $value');
      });
    }
    
    // Log headers
    if (headers != null) {
      print('\n--- Request Headers ---');
      headers.forEach((key, value) {
        print('$key: $value');
      });
    }
  }

  /// Log detailed information about an API response
  static void logApiResponse({
    required http.Response response,
  }) {
    print('\n===== DETAILED API RESPONSE LOGGING =====');
    print('Status Code: ${response.statusCode}');
    print('Headers: ${response.headers}');
    
    try {
      final decodedBody = json.decode(response.body);
      print('\n--- Response Body Details ---');
      _printNestedMap(decodedBody);
    } catch (e) {
      print('Raw Response Body: ${response.body}');
      print('Error parsing JSON: $e');
    }
  }

  /// Recursively print nested map structures
  static void _printNestedMap(dynamic data, {int indent = 0}) {
    final indentString = '  ' * indent;
    
    if (data is Map) {
      data.forEach((key, value) {
        print('$indentString$key (${value.runtimeType}): $value');
        if (value is Map || value is List) {
          _printNestedMap(value, indent: indent + 1);
        }
      });
    } else if (data is List) {
      data.asMap().forEach((index, value) {
        print('$indentString[$index] (${value.runtimeType}): $value');
        if (value is Map || value is List) {
          _printNestedMap(value, indent: indent + 1);
        }
      });
    }
  }

  /// Comprehensive error logging method
  static void logErrorDetails({
    required String operation,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  }) {
    print('\n===== ERROR LOGGING =====');
    print('Operation: $operation');
    print('Error Type: ${error.runtimeType}');
    print('Error Message: $error');
    
    if (additionalContext != null) {
      print('\n--- Additional Context ---');
      additionalContext.forEach((key, value) {
        print('$key (${value.runtimeType}): $value');
      });
    }
    
    if (stackTrace != null) {
      print('\n--- Stack Trace ---');
      print(stackTrace);
    }
  }

  /// Validate and log type mismatches
  static bool validateRequestParameters(Map<String, dynamic> parameters) {
    print('\n===== PARAMETER VALIDATION =====');
    bool isValid = true;
    
    parameters.forEach((key, value) {
      print('$key: ${value.runtimeType} = $value');
      
      // Add specific type checks based on your API requirements
      switch (key) {
        case 'requestId':
          if (value is! String) {
            print('⚠️ WARNING: requestId should be a String');
            isValid = false;
          }
          break;
        case 'doctorId':
          if (value is! String) {
            print('⚠️ WARNING: doctorId should be a String');
            isValid = false;
          }
          break;
      }
    });
    
    return isValid;
  }
}