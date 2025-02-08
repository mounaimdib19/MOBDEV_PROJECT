import 'package:flutter/material.dart';
import 'logout_handler.dart';
import 'doctor_bottom_nav_bar.dart';
import 'notifications_settings.dart';
import 'privacy_security_settings.dart';
import 'language_settings.dart';
import 'about_settings.dart';

class DoctorSettingsScreen extends StatelessWidget {
  final String id_doc;
  const DoctorSettingsScreen({super.key, required this.id_doc});

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
      bottomNavigationBar: DoctorBottomNavBar(
        currentIndex: 3,
        id_doc: id_doc,
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
          _buildSettingsItem(context, 'Privacy and Security', 'assets/images/secure.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacySecuritySettings()));
          }),
          _buildSettingsItem(context, 'Languages', 'assets/images/language.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettings()));
          }),
          _buildSettingsItem(context, 'About', 'assets/images/secure.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutSettings()));
          }),
          _buildSettingsItem(context, 'Logout', 'assets/images/logout.png', () async {
            final shouldLogout = await _showLogoutConfirmationDialog(context);
            if (shouldLogout && context.mounted) {
              await LogoutHandler.logout(context);
            }
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
            color: const Color.fromARGB(255, 36, 200, 60),
          ),
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: Color.fromARGB(255, 34, 202, 104)),
        onTap: onTap,
      ),
    );
  }

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('deconnexion'), 
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('deconnexion'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class TopShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color.fromARGB(255, 87, 223, 110), const Color.fromARGB(255, 26, 160, 93)],
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