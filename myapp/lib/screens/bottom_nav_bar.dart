import 'package:flutter/material.dart';
import 'patient_profile_screen.dart';
import 'settings_screen.dart';
import 'book_appointment_screen.dart';
import 'welcome_screen.dart';
import 'patient_appointments_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int id_patient;

  const BottomNavBar({
    super.key, 
    required this.currentIndex, 
    required this.onTap, 
    required this.id_patient
  });

  void _handleNavigation(BuildContext context, int index) {
  if (index < -1 || index > 5) {
    print('Invalid navigation index: $index');
    return;
  }

  final safePatientId = id_patient ?? 0;

  switch (index) {
    case 0:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen(id_patient: safePatientId)),
      );
      break;
    case 1:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PatientAppointmentsScreen(id_patient: safePatientId.toString())),
      );
      break;
    case 2:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BookAppointmentScreen(id_patient: safePatientId)),
      );
      break;
    case 3:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PatientProfileScreen(id_patient: safePatientId)),
      );
      break;
    case 4:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SettingsScreen(id_patient: safePatientId)),
      );
      break;
  }
  
  onTap(index);
}

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(context, 'assets/images/home.png', 0),
                _buildNavItem(context, 'assets/images/secure.png', 1),
                const SizedBox(width: 60), // Space for the center button
                _buildNavItem(context, 'assets/images/user.png', 3),
                _buildNavItem(context, 'assets/images/setting.png', 4),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 32,
          child: _buildAddButton(context),
        ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, String iconPath, int index) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => _handleNavigation(context, index),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.fromARGB(255, 28, 92, 141), Color.fromARGB(255, 81, 202, 227)],
                ).createShader(bounds)
              : const LinearGradient(
                  colors: [Colors.grey, Colors.grey],
                ).createShader(bounds);
        },
        child: Image.asset(
          iconPath,
          color: Colors.white,
          width: isSelected ? 40 : 33,
          height: isSelected ? 40 : 33,
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleNavigation(context, 2), // Use index 2 for center button
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF206BA4),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF206BA4).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/plus.png',
              color: Colors.white,
              width: 50,
              height: 50,
            ),
            const Icon(Icons.add, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}