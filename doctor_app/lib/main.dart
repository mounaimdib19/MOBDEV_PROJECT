import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'firebase_options.dart';
import 'screens/doctor_login_screen.dart';
import 'screens/doctor_welcome_screen.dart';
import 'services/fcm_service.dart';
import 'services/session_manager.dart';
import 'services/location_service.dart';
import '../config/environment.dart';
import 'dart:convert';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == LocationService.updateLocationTask) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final doctorId = inputData?['doctorId'];
        
        if (doctorId != null) {
          final response = await http.post(
            Uri.parse(Environment.updateDoctorLocation),
            body: {
              'id_doc': doctorId,
              'latitude': position.latitude.toString(),
              'longitude': position.longitude.toString(),
            },
          );
          
          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            return responseData['success'] ?? false;
          }
        }
      }
      return false;
    } catch (e) {
      print('Background task error: $e');
      return false;
    }
  });
}

Future<bool> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException('Firebase initialization timed out'),
    );
    return true;
  } catch (e) {
    print('Firebase initialization error: $e');
    // Try one more time after a short delay
    await Future.delayed(const Duration(seconds: 2));
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));
      return true;
    } catch (e) {
      print('Firebase second initialization attempt failed: $e');
      return false;
    }
  }
}

Future<void> main() async {
  try {
    // Ensure Flutter bindings are initialized first
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Initialize Firebase with retry
    bool firebaseInitialized = await initializeFirebase();
    if (!firebaseInitialized) {
      throw Exception('Failed to initialize Firebase after retries');
    }
    
    // Initialize services with timeouts and retries
    await Future.wait([
      FCMService.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('FCM initialization timed out'),
      ),
      LocationService.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Location service initialization timed out'),
      ),
    ]).catchError((error) {
      print('Service initialization error: $error');
      // Continue even if some services fail
    });
    
    // Check for existing session
    final isLoggedIn = await SessionManager.isLoggedIn();
    final doctorId = await SessionManager.getDoctorId();
    
    // Start location tracking if doctor is logged in
    if (isLoggedIn && doctorId != null) {
      try {
        await LocationService.startLocationTracking(doctorId).timeout(
          const Duration(seconds: 10),
        );
      } catch (e) {
        print('Location tracking initialization error: $e');
        // Continue even if location tracking fails
      }
    }
    
    // Schedule periodic token refresh
    Timer.periodic(const Duration(hours: 12), (timer) async {
      if (await SessionManager.isLoggedIn()) {
        final doctorId = await SessionManager.getDoctorId();
        if (doctorId != null) {
          await FCMService.updateToken(doctorId);
        }
      }
    });
    
    runApp(MyApp(
      isLoggedIn: isLoggedIn, 
      doctorId: doctorId,
    ));
  } catch (e) {
    print('Critical error initializing app: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final String? doctorId;

  const MyApp({
    super.key, 
    required this.isLoggedIn, 
    this.doctorId,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupInteractedMessage();
  }

  Future<void> _setupInteractedMessage() async {
    try {
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    } catch (e) {
      print('Error setting up message handling: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    try {
      if (message.data['type'] == 'assistance_request') {
        if (widget.isLoggedIn && widget.doctorId != null) {
          navigatorKey.currentState?.pushNamed(
            '/assistance-requests',
            arguments: {'doctorId': widget.doctorId},
          );
        }
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Doctor App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: widget.isLoggedIn && widget.doctorId != null
          ? DoctorWelcomeScreen(id_doc: widget.doctorId!)
          : const DoctorLoginScreen(),
      onGenerateRoute: (settings) {
        return null;
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, this.error = 'Failed to initialize application'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  // Clear any cached data that might be causing issues
                  await Firebase.initializeApp().then((_) => Firebase.app().delete());
                  SystemNavigator.pop();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}