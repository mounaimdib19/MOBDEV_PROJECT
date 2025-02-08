import 'package:flutter/material.dart';
import 'notifications_settings.dart';
import 'privacy_security_settings.dart';
import 'language_settings.dart';
import 'about_settings.dart';
import 'logout_handler.dart';
import 'bottom_nav_bar.dart';

class SettingsScreen extends StatelessWidget {
  final int id_patient; 
  const SettingsScreen({super.key, required this.id_patient}); // Add this constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSettingsList(context),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: (index) {
          // Handle navigation here if needed
        },
        id_patient: id_patient,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.25,
      width: double.infinity,
      child: CustomPaint(
        painter: TopShapePainter(),
        child: const SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Settings',
                style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSettingsItem(context, 'Notifications', 'assets/images/notification.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsSettings()));
          }),
          _buildSettingsItem(context, 'Confidentialité et sécurité', 'assets/images/secure.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacySecuritySettings()));
          }),
          _buildSettingsItem(context, 'Langages', 'assets/images/language.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettings()));
          }),
          _buildSettingsItem(context, 'A propos', 'assets/images/secure.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutSettings()));
          }),
          _buildSettingsItem(context, 'Déconnexion', 'assets/images/logout.png', () {
            _showLogoutConfirmationDialog(context);
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, String title, String iconPath, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            iconPath,
            color: const Color(0xFF1B5A90),
          ),
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF1B5A90)),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                LogoutHandler.logout(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class TopShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blue[300]!, Colors.blue[700]!],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..lineTo(0, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.95)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}