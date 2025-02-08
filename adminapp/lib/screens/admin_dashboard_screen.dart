import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_bottom_nav_bar.dart';
import 'dart:async';
import 'view_patients_screen.dart';
import 'view_appointments_screen.dart';
import 'add_patient_screen.dart';
import 'view_administrators_screen.dart';
import 'view_requests_screen.dart';
import 'add_administrator_screen.dart';
import 'view_doctors_screen.dart';
import 'add_doctor_screen.dart';
import 'display_services_screen.dart';
import 'add_service_screen.dart';
import 'view_assistants_screen.dart';
import 'admin_profile_screen.dart';
import '../config/environment.dart';
import 'specialty_management_screen.dart';

class AdminWelcomeScreen extends StatefulWidget {
  final int idAdmin;

  const AdminWelcomeScreen({super.key, required this.idAdmin});

  @override
  _AdminWelcomeScreenState createState() => _AdminWelcomeScreenState();
}

class _AdminWelcomeScreenState extends State<AdminWelcomeScreen> {
  String _adminName = '';
  bool _isActive = false;
  int _currentIndex = 0;
  Timer? _statusUpdateTimer;
  String _adminType = '';
  final List<bool> _isExpanded = List.generate(6, (_) => false);

  @override
  void initState() {
    super.initState();
    _fetchAdminInfo();
    _startStatusUpdateTimer();
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  void _startStatusUpdateTimer() {
    _statusUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _fetchAdminInfo();
    });
  }

  Future<void> _fetchAdminInfo() async {
    try {
      final response = await http.get(
        Uri.parse(Environment.getadmininfo(widget.idAdmin)),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _adminName = '${data['prenom']} ${data['nom']}';
            _isActive = data['statut'] == 'active';
            _adminType = data['type'];
          });
        }
      }
    } catch (e) {
      print('Error fetching admin info: $e');
    }
  }

  Future<void> _toggleStatus() async {
    try {
      final response = await http.post(
        Uri.parse(Environment.toggleadminstatus()),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_admin': widget.idAdmin,
          'statut': _isActive ? 'inactive' : 'active',
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _isActive = data['new_status'] == 'active';
          });
        }
      }
    } catch (e) {
      print('Error toggling status: $e');
    }
  }

  bool _isSuperAdmin() => _adminType.toLowerCase() == 'superadmin';

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminProfileScreen(idAdmin: widget.idAdmin),
        ),
      );
    }
  }

  void _navigateToScreen(String screenName) {
    final routes = {
      'Afficher les patients': const ViewPatientsScreen(),
      'Ajouter Patient': const AddPatientScreen(),
      'Afficher les demandes': const ViewRequestsScreen(),
      'Afficher les administrateurs': const ViewAdministratorsScreen(),
      'Ajouter un administrateur': const AddAdministratorScreen(),
      'Afficher les Services': const DisplayServicesScreen(),
      'Afficher les rendez-vous': const ViewAppointmentsScreen(),
      'Ajouter un Service': const AddServicesScreen(),
      'Afficher les médecins': const ViewDoctorsScreen(type: 'doctor'),
      'Afficher les infirmières': const ViewDoctorsScreen(type: 'nurse'),
      'Afficher les gardes malades': const ViewDoctorsScreen(type: 'gm'),
      'Afficher les assistants': const ViewAssistantsScreen(),
      'Ajouter un médecin': const AddDoctorScreen(),
      'Gérer les spécialités': const SpecialtyManagementScreen(),
    };

    final targetScreen = routes[screenName];
    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: const Color(0xFF2C3E50),
          elevation: 0,
          title: const Text(
            'Tableau de bord administrateur',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildMainDashboard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: _currentIndex,
        idAdmin: widget.idAdmin,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenue,',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _adminName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _adminType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusToggle(),
        ],
      ),
    );
  }

  Widget _buildStatusToggle() {
    return GestureDetector(
      onTap: _toggleStatus,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isActive ? Colors.green[300] : Colors.red[300],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: _isActive ? Colors.green[100] : Colors.red[100],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Console de gestion',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),
        _buildDashboardList(),
      ],
    );
  }

  Widget _buildDashboardList() {
    final sections = [
      if (_isSuperAdmin())
        _buildSection(
          0,
          'Gestion des services',
          Icons.medical_services,
          const Color(0xFF3498DB),
          ['Afficher les Services', 'Ajouter un Service'],
        ),
      _buildSection(
        1,
        'Gestion de patient',
        Icons.people,
        const Color(0xFF2ECC71),
        ['Afficher les patients', 'Ajouter Patient'],
      ),
      _buildSection(
        2,
        'Gestion des demandes',
        Icons.assignment,
        const Color(0xFFE74C3C),
        ['Afficher les demandes'],
      ),
      _buildSection(
        3,
        'Gestion des rendez-vous',
        Icons.calendar_today,
        const Color(0xFF9B59B6),
        ['Afficher les rendez-vous'],
      ),
      if (_isSuperAdmin())
        _buildSection(
          4,
          'Gestion des administrateurs',
          Icons.admin_panel_settings,
          const Color(0xFFF39C12),
          ['Afficher les administrateurs', 'Ajouter un administrateur'],
        ),
      _buildSection(
        5,
        'Gestion des professionnels de santé',
        Icons.health_and_safety,
        const Color(0xFF1ABC9C),
        ['Afficher les médecins', 'Afficher les infirmières', 'Afficher les gardes malades', 'Afficher les assistants', 'Ajouter un médecin', 'Gérer les spécialités'],
      ),
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: sections[index],
      ),
    );
  }

  Widget _buildSection(int index, String title, IconData icon, Color color, List<String> actions) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded[index],
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded[index] = expanded;
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions.map((action) => _buildActionButton(action, color)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String action, Color color) {
    return ElevatedButton(
      onPressed: () => _navigateToScreen(action),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        action,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}