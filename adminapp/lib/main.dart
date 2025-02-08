import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_profile_screen.dart';
import 'services/admin_session_manager.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AdminFCMService.showNotification(message);
}

Future<void> main() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set up background handler before initializing FCM
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Initialize FCM service
    await AdminFCMService.initialize();
    
    // Check for existing session
    final isLoggedIn = await AdminSessionManager.isLoggedIn();
    final adminId = await AdminSessionManager.getAdminId();
    
    runApp(MyApp(
      isLoggedIn: isLoggedIn,
      adminId: adminId,
    ));
  } catch (e) {
    print('Error initializing app: $e');
    runApp(const ErrorApp());
  }
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final int? adminId;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.adminId,
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
      // Handle initial message when app is terminated
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // Handle message interaction when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    } catch (e) {
      print('Error setting up message handling: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    try {
      if (widget.isLoggedIn && widget.adminId != null) {
        // Handle navigation based on message data
        final String? type = message.data['type'] as String?;
        final String? id = message.data['id'] as String?;
        
        if (type != null) {
          switch (type) {
            case 'appointment':
              navigatorKey.currentState?.pushNamed(
                '/dashboard',
                arguments: {'adminId': widget.adminId},
              );
              break;
            case 'profile':
              navigatorKey.currentState?.pushNamed(
                '/profile',
                arguments: {'adminId': widget.adminId},
              );
              break;
            default:
              navigatorKey.currentState?.pushNamed(
                '/notification',
                arguments: message.data,
              );
          }
        }
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  MaterialPageRoute _redirectToLogin() {
    return MaterialPageRoute(
      builder: (context) => const AdminLoginScreen(),
    );
  }

  Widget _handleNotificationNavigation(Map<String, dynamic> payload) {
    final String? type = payload['type'] as String?;
    final String? id = payload['id'] as String?;
    
    switch (type) {
      case 'appointment':
        return AdminWelcomeScreen(idAdmin: widget.adminId!);
      case 'profile':
        return AdminProfileScreen(idAdmin: widget.adminId!);
      default:
        return AdminWelcomeScreen(idAdmin: widget.adminId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Admin Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5A90)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5A90),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5A90),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      onGenerateRoute: (settings) {
        // If not logged in and not on login screen, redirect to login
        if (!widget.isLoggedIn && settings.name != '/login') {
          return _redirectToLogin();
        }

        // Handle null adminId case first to avoid repeated null checks
        if (widget.adminId == null && settings.name != '/login') {
          return _redirectToLogin();
        }

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => widget.isLoggedIn && widget.adminId != null
                  ? AdminWelcomeScreen(idAdmin: widget.adminId!)
                  : const AdminLoginScreen(),
            );
          case '/dashboard':
            return MaterialPageRoute(
              builder: (context) => AdminWelcomeScreen(idAdmin: widget.adminId!),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (context) => AdminProfileScreen(idAdmin: widget.adminId!),
            );
          case '/notification':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              return MaterialPageRoute(
                builder: (context) => _handleNotificationNavigation(args),
              );
            }
            return _redirectToLogin();
          default:
            return _redirectToLogin();
        }
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

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
              const Text(
                'Failed to initialize application',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}