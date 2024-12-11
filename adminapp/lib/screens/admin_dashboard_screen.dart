import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_bottom_nav_bar.dart';
import 'dart:async';
import 'view_patients_screen.dart';
import 'delete_service_screen.dart';
import 'delete_doctor_screen.dart';
import 'delete_administrator_screen.dart';
import 'delete_patient_screen.dart';
import 'add_patient_screen.dart';
import 'view_administrators_screen.dart';
import 'add_administrator_screen.dart';
import 'view_doctors_screen.dart';
import 'add_doctor_screen.dart';
import 'display_services_screen.dart';
import 'add_service_screen.dart';
import 'view_assistants_screen.dart';
import 'admin_profile_screen.dart';
import '../config/environment.dart';



class AdminWelcomeScreen extends StatefulWidget {
  final int id_admin;

  const AdminWelcomeScreen({super.key, required this.id_admin});

  @override
  _AdminWelcomeScreenState createState() => _AdminWelcomeScreenState();
}

class _AdminWelcomeScreenState extends State<AdminWelcomeScreen> {
  String _adminName = '';
  bool _isActive = false;
  int _currentIndex = 0;
  Timer? _statusUpdateTimer;
  String _adminType = '';

  @override
  void initState() {
    super.initState();
    _fetchAdminInfo();
    _startStatusUpdateTimer();
  }

  @override
  void dispose() {
    _stopStatusUpdateTimer();
    super.dispose();
  }

  void _startStatusUpdateTimer() {
    _statusUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _fetchAdminInfo();
    });
  }

  void _stopStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = null;
  }

   Future<void> _fetchAdminInfo() async {
    try {
      final response = await http.get(
        Uri.parse(
            Environment.getadmininfo(widget.id_admin)),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _adminName = '${data['prenom']} ${data['nom']}';
            _isActive = data['statut'] == 'active';
            _adminType = data['type']; // Store the admin type
          });
        } else {
          print('API returned success: false. Message: ${data['message']}');
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching admin info: $e');
      if (e is FormatException) {
        print('Response was not valid JSON. Raw response: ${e.source}');
      }
    }
  }
  

  bool _isSuperAdmin() {
    return _adminType.toLowerCase() == 'superadmin';
  }

  Future<void> _toggleStatus() async {
    try {
      final response = await http.post(
        Uri.parse(
           Environment.toggleadminstatus()),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_admin': widget.id_admin,
          'statut': _isActive ? 'inactive' : 'active',
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _isActive = data['new_status'] == 'active';
          });
        } else {
          print('Failed to toggle status: ${data['message']}');
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling status: $e');
    }
  }

  void _navigateToScreen(String screen) {
    switch (screen) {
      case 'View Patients':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ViewPatientsScreen()),
        );
        break;
      case 'Add Patient':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddPatientScreen()),
        );
        break;
      case 'View Administrators':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ViewAdministratorsScreen()),
        );
        break;
      case 'Add Administrator':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddAdministratorScreen()),
        );
        break;
      case 'View Services':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DisplayServicesScreen()),
        );
        break;
      case 'Add Service':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddServicesScreen()),
        );
        break;
      case 'View Doctors':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ViewDoctorsScreen(type: 'doctor')),
        );
        break;
      case 'View Nurses':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ViewDoctorsScreen(type: 'nurse')),
        );
        break;
      case 'View Gardes Malades':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ViewDoctorsScreen(type: 'gm')),
        );
        break;
      case 'View Assistants':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ViewAssistantsScreen()),
        );
        break;
      case 'Add Doctor':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddDoctorScreen()),
        );
        break;
      default:
        print('Navigating to $screen');
    }
  }

   void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        // Dashboard (current screen)
        break;
      case 1:
        // Navigate to AdminProfileScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminProfileScreen(id_admin: widget.id_admin),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $_adminName',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status: ${_isActive ? 'Active' : 'Inactive'}',
                        style: TextStyle(fontSize: 18, color: _isActive ? Colors.green : Colors.red),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (value) {
                          _toggleStatus();
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isSuperAdmin()) ...[
                _buildSectionTitle('Service Management'),
                _buildButtonRow('View Services', 'Add Service'),
                _buildDeleteButton('Delete Service'),
                const SizedBox(height: 20),
              ],
              _buildSectionTitle('Patient Management'),
              _buildButtonRow('View Patients', 'Add Patient'),
              _buildDeleteButton('Delete Patient'),
              const SizedBox(height: 20),
              _buildSectionTitle('Appointment Management'),
              _buildButtonRow('View Appointments', 'Add Appointment'),
              const SizedBox(height: 20),
              if (_isSuperAdmin()) ...[
                _buildSectionTitle('Administrator Management'),
                _buildButtonRow('View Administrators', 'Add Administrator'),
                _buildDeleteButton('Delete Administrator'),
                const SizedBox(height: 20),
              ],
              _buildHealthcareProfessionalManagementSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
      ),
    );
  }

  Widget _buildButtonRow(String leftButtonText, String rightButtonText) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _navigateToScreen(leftButtonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(leftButtonText),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _navigateToScreen(rightButtonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(rightButtonText),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton(String buttonText) {
  return Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: ElevatedButton(
      onPressed: () {
        switch (buttonText) {
          case 'Delete Doctor':
            Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DeleteDoctorScreen()),
      );
            break;
          case 'Delete Administrator':
            Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DeleteAdministratorScreen()),
      );
            break;
          case 'Delete Patient':
            Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DeletePatientScreen()),
      );
            break;
           case 'Delete Service':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DeleteServiceScreen()),
      );
      break;
          default:
            print('Unhandled delete action: $buttonText');
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(buttonText),
    ),
  );
}


  Widget _buildHealthcareProfessionalManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Healthcare Professional Management'),
        ElevatedButton(
          onPressed: () => _navigateToScreen('View Doctors'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('View Doctors'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _navigateToScreen('View Nurses'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('View Nurses'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _navigateToScreen('View Gardes Malades'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('View Gardes Malades'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _navigateToScreen('View Assistants'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('View Assistants'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _navigateToScreen('Add Doctor'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Add Healthcare Professional'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _navigateToScreen('Add Doctor'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Add Healthcare Professional'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _navigateToScreen('Delete Healthcare Professional'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Delete Healthcare Professional'),
        ),
      ],
    );
  }
}