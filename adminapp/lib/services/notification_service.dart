import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import '../firebase_options.dart';
import 'admin_session_manager.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AdminFCMService.showNotification(message);
}

class AdminFCMService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  static const channelId = 'admin_channel';
  static const channelName = 'Admin Notifications';
  static const channelDescription = 'Channel for admin notifications';
  
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      await _requestPermissions();
      await _initializeLocalNotifications();
      
      FirebaseMessaging.onMessage.listen(showNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);
      await _handleInitialMessage();
      
      await _updateTokenIfLoggedIn();
      FirebaseMessaging.instance.onTokenRefresh.listen(_handleTokenRefresh);
    } catch (e) {
      print('Error initializing Admin FCM service: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
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

  static Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      
      await _notifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
      );
      
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

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'platform': 'android',
          'version': androidInfo.version.release,
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
    return {'platform': Platform.operatingSystem};
  }

  static Future<String?> getFCMToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> updateToken(String adminId) async {
    try {
      final token = await getFCMToken();
      if (token == null) return;

      final deviceInfo = await _getDeviceInfo();
      
      final response = await http.post(
        Uri.parse(Environment.updateAdminFCMToken),
        body: json.encode({
          'id_admin': adminId,
          'fcm_token': token,
          'device_info': json.encode(deviceInfo)
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update FCM token: ${response.body}');
      }
    } catch (e) {
      print('Error updating admin token: $e');
    }
  }

  static Future<void> deactivateToken() async {
    try {
      final token = await getFCMToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse(Environment.deactivateAdminToken),
        body: json.encode({'fcm_token': token}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to deactivate admin FCM token: ${response.body}');
      }
      
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      print('Error deactivating admin FCM token: $e');
    }
  }

  // Helper methods for handling notifications
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
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );
    
    final ios = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    
    await _notifications.show(
      DateTime.now().millisecond,
      message.notification?.title ?? 'Nouvelle requete',
      message.notification?.body,
      NotificationDetails(android: android, iOS: ios),
      payload: json.encode(message.data),
    );
  } catch (e) {
    print('Error showing notification: $e');
  }
}

  static Future<void> _handleTokenRefresh(String token) async {
    final adminId = await AdminSessionManager.getAdminId();
    if (adminId != null) {
      await updateToken(adminId.toString());
    }
  }

  static Future<void> _updateTokenIfLoggedIn() async {
    final isLoggedIn = await AdminSessionManager.isLoggedIn();
    final adminId = await AdminSessionManager.getAdminId();
    
    if (isLoggedIn && adminId != null) {
      await updateToken(adminId.toString());
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
    // Add navigation logic based on message data
    print('Admin notification clicked: ${message.data}');
  }
}