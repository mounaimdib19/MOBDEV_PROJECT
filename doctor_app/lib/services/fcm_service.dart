import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import '../firebase_options.dart';
import '../services/session_manager.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FCMService.showNotification(message);
}

class FCMService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  static const channelId = 'high_importance_channel';
  static const channelName = 'Urgent Notifications';
  static const channelDescription = 'Channel for urgent notifications';
  
  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      
      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Request permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(showNotification);
      
      // Handle background/terminated state message clicks
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);
      await _handleInitialMessage();
      
      // Update token if user is logged in
      await _updateTokenIfLoggedIn();
      
      // Set up token refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen(_handleTokenRefresh);
      
    } catch (e) {
      print('Error initializing FCM service: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
        provisional: false,
        carPlay: false,
        announcement: false,
      );
      
      // Request provisional authorization for iOS
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }
  
  static Future<void> _handleTokenRefresh(String token) async {
    try {
      final isLoggedIn = await SessionManager.isLoggedIn();
      final doctorId = await SessionManager.getDoctorId();
      
      if (isLoggedIn && doctorId != null) {
        final deviceInfo = await _getDeviceInfo();
        
        int maxRetries = 3;
        int retryCount = 0;
        bool success = false;

        while (!success && retryCount < maxRetries) {
          try {
            final response = await http.post(
              Uri.parse(Environment.updateFCMToken),
              body: json.encode({
                'id_doc': doctorId,
                'fcm_token': token,
                'device_info': json.encode(deviceInfo)
              }),
              headers: {'Content-Type': 'application/json'},
            ).timeout(const Duration(seconds: 10));
            
            if (response.statusCode == 200) {
              final responseData = json.decode(response.body);
              success = responseData['success'] ?? false;
              print('Token refresh update ${success ? 'successful' : 'failed'}: ${response.body}');
              break;
            }
          } catch (e) {
            print('Error updating refreshed token (attempt ${retryCount + 1}): $e');
            await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
            retryCount++;
          }
        }
      }
    } catch (e) {
      print('Fatal error handling token refresh: $e');
    }
  }


  static Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );
      
      await _notifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
      );
      
      // Create high importance channel for Android
      final channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );
      
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  static void _handleLocalNotificationResponse(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null) {
        final data = json.decode(payload);
        _handleMessageClick(RemoteMessage(data: data));
      }
    } catch (e) {
      print('Error handling local notification response: $e');
    }
  }

  static Future<void> showNotification(RemoteMessage message) async {
    try {
      final android = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        visibility: NotificationVisibility.public,
      );
      
      final ios = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
      
      await _notifications.show(
        DateTime.now().millisecond,
        message.notification?.title ?? 'Assistance telephonique',
        message.notification?.body ?? 'Vous avez une nouvelle demande',
        NotificationDetails(android: android, iOS: ios),
        payload: json.encode(message.data),
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }
  
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'platform': 'android',
          'version': androidInfo.version.release,
          'sdk_version': androidInfo.version.sdkInt.toString(),
          'device_id': androidInfo.id,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'manufacturer': 'Apple',
          'model': iosInfo.model,
          'platform': 'ios',
          'version': iosInfo.systemVersion,
          'device_id': iosInfo.identifierForVendor ?? 'unknown',
        };
      }
    } catch (e) {
      print('Error getting device info: $e');
    }
    
    return {
      'manufacturer': 'Unknown',
      'model': 'Unknown',
      'platform': Platform.operatingSystem,
      'version': 'unknown',
      'device_id': 'unknown',
    };
  }

    static Future<String?> getFCMToken({int maxRetries = 3}) async {
    int retryCount = 0;
    String? token;
    
    while (retryCount < maxRetries && token == null) {
      try {
        // Check if Firebase is initialized
        if (!Firebase.apps.isNotEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }

        // Ensure permissions are granted before requesting token
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          await _requestPermissions();
        }

        token = await FirebaseMessaging.instance.getToken();
        
        if (token == null) {
          print('FCM token is null, attempt ${retryCount + 1} of $maxRetries');
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1))); // Exponential backoff
          retryCount++;
        }
      } catch (e) {
        print('Error getting FCM token (attempt ${retryCount + 1}): $e');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        retryCount++;
      }
    }

    if (token == null) {
      print('Failed to get FCM token after $maxRetries attempts');
    } else {
      print('Successfully obtained FCM token: ${token.substring(0, 10)}...');
    }

    return token;
  }

  static Future<void> _updateTokenIfLoggedIn() async {
    try {
      final isLoggedIn = await SessionManager.isLoggedIn();
      final doctorId = await SessionManager.getDoctorId();
      
      if (isLoggedIn && doctorId != null) {
        await updateToken(doctorId);
      }
    } catch (e) {
      print('Error updating token on startup: $e');
    }
  }

  static Future<void> updateToken(String doctorId) async {
    try {
      final token = await getFCMToken(maxRetries: 3);
      if (token == null) {
        print('Could not update token: token generation failed');
        return;
      }

      final deviceInfo = await _getDeviceInfo();
      
      // Add retry logic for the API call
      int maxRetries = 3;
      int retryCount = 0;
      bool success = false;

      while (!success && retryCount < maxRetries) {
        try {
          final response = await http.post(
            Uri.parse(Environment.updateFCMToken),
            body: json.encode({
              'id_doc': doctorId,
              'fcm_token': token,
              'device_info': json.encode(deviceInfo)
            }),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            success = responseData['success'] ?? false;
            print('Token update ${success ? 'successful' : 'failed'}: ${response.body}');
            break;
          }
        } catch (e) {
          print('Error updating token (attempt ${retryCount + 1}): $e');
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          retryCount++;
        }
      }
    } catch (e) {
      print('Fatal error updating token: $e');
    }
  }


  static Future<void> deactivateToken() async {
    try {
      final token = await getFCMToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse(Environment.deactivateToken),
        body: json.encode({'fcm_token': token}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to deactivate FCM token: ${response.body}');
      }
      
      // Delete the token from Firebase
      await FirebaseMessaging.instance.deleteToken();
      
    } catch (e) {
      print('Error deactivating FCM token: $e');
      rethrow;
    }
  }
  
  static Future<void> _handleInitialMessage() async {
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null) {
        _handleMessageClick(message);
      }
    } catch (e) {
      print('Error handling initial message: $e');
    }
  }
  
  static void _handleMessageClick(RemoteMessage message) {
    try {
      print('Message clicked: ${message.data}');
      // Add your navigation logic here based on message data
      if (message.data['type'] == 'assistance_request') {
        // Navigate to assistance requests screen
        // Example: Navigator.pushNamed(context, '/assistance-requests');
      }
    } catch (e) {
      print('Error handling message click: $e');
    }
  }
}