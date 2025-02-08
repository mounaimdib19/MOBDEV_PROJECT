import 'package:flutter/material.dart';
import 'doctor_welcome_screen.dart';
import 'doctor_completed_appointments_screen.dart';
import 'doctor_profile_screen.dart';
import 'doctor_settings_screen.dart';

class DoctorBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String id_doc;

  const DoctorBottomNavBar({super.key, 
    required this.currentIndex,
    required this.id_doc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: (index) {
            if (index != currentIndex) {
              switch (index) {
                case 0:
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => DoctorWelcomeScreen(id_doc: id_doc)),
                    (route) => false,
                  );
                  break;
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DoctorCompletedAppointmentsScreen(id_doc: id_doc)),
                  );
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DoctorProfileScreen(id_doc: int.parse(id_doc))),
                  );
                  break;
                case 3:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DoctorSettingsScreen(id_doc: id_doc)),
                  );
                  break;
              }
            }
          },
          elevation: 8,
          backgroundColor: const Color.fromARGB(255, 33, 194, 95),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          items: [
            _buildBottomNavItem('assets/images/home.png', 'Accueil'),
            _buildBottomNavItem('assets/images/medical-appointment.png', 'Historique'),
            _buildBottomNavItem('assets/images/user.png', 'Profile'),
            _buildBottomNavItem('assets/images/setting.png', 'paramètres'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(String iconPath, String label) {
    return BottomNavigationBarItem(
      icon: Image.asset(
        iconPath,
        width: 24,
        height: 24,
        color: Colors.white.withOpacity(0.6),
      ),
      activeIcon: Image.asset(
        iconPath,
        width: 24,
        height: 24,
        color: Colors.white,
      ),
      label: label,
    );
  }
}