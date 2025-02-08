import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_profile_screen.dart';
import '../services/admin_session_manager.dart';

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final int idAdmin;

  const AdminBottomNavBar({
    super.key, 
    required this.currentIndex,
    required this.idAdmin,
  });

  Future<void> _handleNavigation(BuildContext context, int index) async {
    if (index != currentIndex) {
      // Check if user is logged in and has valid admin ID
      final isLoggedIn = await AdminSessionManager.isLoggedIn();
      final storedAdminId = await AdminSessionManager.getAdminId();
      
      // Validate session
      if (!isLoggedIn || storedAdminId == null || storedAdminId != idAdmin) {
        if (context.mounted) {
          await AdminSessionManager.clearSession();
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }
      }

      if (context.mounted) {
        switch (index) {
          case 0:
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => AdminWelcomeScreen(idAdmin: idAdmin)
              ),
              (route) => false,
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminProfileScreen(idAdmin: idAdmin)
              ),
            );
            break;
        }
      }
    }
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Icon(icon),
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: (index) => _handleNavigation(context, index),
          backgroundColor: const Color(0xFF1B5A90),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          selectedFontSize: 14,
          unselectedFontSize: 14,
          items: [
            _buildNavItem(Icons.dashboard_outlined, 'Tableau de bord'),
            _buildNavItem(Icons.person_outline, 'Profile'),
          ],
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}