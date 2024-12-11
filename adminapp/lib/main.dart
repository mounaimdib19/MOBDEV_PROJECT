import 'package:flutter/material.dart';
import 'screens/admin_login_screen.dart'; // Import the DoctorLoginScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Login App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AdminLoginScreen(), // Set DoctorLoginScreen as the home widget
    );
  }
}