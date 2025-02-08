import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'bottom_nav_bar.dart';
import '../config/environment.dart';

class PatientProfileScreen extends StatefulWidget {
  final int id_patient;

  const PatientProfileScreen({super.key, required this.id_patient});

  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  Map<String, dynamic> _patientData = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchPatientInfo();
  }

  Future<void> _fetchPatientInfo() async {
    try {
      final response = await http.get(
        Uri.parse(Environment.getPatientProfile(widget.id_patient)),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _patientData = Map<String, dynamic>.from(data['patient']);
            _patientData.forEach((key, value) {
              _patientData[key] = value?.toString() ?? '';
            });
            _patientData['id_patient'] = widget.id_patient;
          });
        } else {
          print('API returned success: false. Message: ${data['message']}');
        }
      } else {
        print('Failed to load patient data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching patient info: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final response = await http.post(
          Uri.parse(Environment.updatePatientProfile),
          body: {
            'id_patient': widget.id_patient.toString(),
            'nom': _patientData['nom'] ?? '',
            'prenom': _patientData['prenom'] ?? '',
            'adresse_email': _patientData['adresse_email'] ?? '',
            'adresse': _patientData['adresse'] ?? '',
            'wilaya': _patientData['wilaya'] ?? '',
            'commune': _patientData['commune'] ?? '',
            'parent_nom': _patientData['parent_nom'] ?? '',
            'parent_num': _patientData['parent_num']?.toString() ?? '',
            'groupe_sanguin': _patientData['groupe_sanguin'] ?? '',
            'sexe': _patientData['sexe'] ?? '',
            'date_naissance': _patientData['date_naissance'] ?? '',
            'latitude': _patientData['latitude']?.toString() ?? '',
            'longitude': _patientData['longitude']?.toString() ?? '',
          },
        );

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          if (data['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
            _fetchPatientInfo();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update profile: ${data['message']}')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile. Status code: ${response.statusCode}')),
          );
        }
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Une erreur s est produite lors de la mise à jour du profil')),
        );
      }
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _patientData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildProfileForm(),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          // Handle navigation here if needed
        },
        id_patient: widget.id_patient,
      ),
    );
  }


 Widget _buildHeader() {
    String displayName = '${_patientData['prenom'] ?? ''} ${_patientData['nom'] ?? ''}'.trim();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.3,
      width: double.infinity,
      child: CustomPaint(
        painter: TopShapePainter(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[300]!, Colors.blue[700]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getInitials(displayName),
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              displayName.isEmpty ? 'No Name' : displayName,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildProfileForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Nom', _patientData['nom'], (value) => _patientData['nom'] = value),
            _buildTextField('Prénom', _patientData['prenom'], (value) => _patientData['prenom'] = value),
            _buildTextField('Email', _patientData['adresse_email'], (value) => _patientData['adresse_email'] = value),
            const SizedBox(height: 20),
            _buildButton('Mettre a jour', _updateProfile),
          ],
        ),
      ),
    );
  }


  Widget _buildTextField(String label, String? initialValue, Function(String) onSaved) {
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
      child: TextFormField(
        initialValue: initialValue ?? '',
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => value!.isEmpty ? 'This field is required' : null,
        onSaved: (value) => onSaved(value ?? ''),
      ),
    );
  }


 Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(text),
      ),
    );
  }
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    List<String> names = name.trim().split(" ");
    if (names.isEmpty) return 'U';
    
    String initials = "";
    if (names.isNotEmpty && names[0].isNotEmpty) {
      initials += names[0][0];
    }
    if (names.length > 1 && names[names.length - 1].isNotEmpty) {
      initials += names[names.length - 1][0];
    }
    
    return initials.toUpperCase().isEmpty ? 'U' : initials.toUpperCase();
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

class ChangePasswordScreen extends StatefulWidget {
  final int id_patient;

  const ChangePasswordScreen({super.key, required this.id_patient});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse(Environment.changePassword),
          body: json.encode({
            'id_patient': widget.id_patient,
            'current_password': _currentPasswordController.text,
            'new_password': _newPasswordController.text,
            'confirm_password': _confirmPasswordController.text,
          }),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
          Navigator.pop(context);
        } else {
          var data = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to change password: ${data['message']}')),
          );
        }
      } catch (e) {
        print('Error changing password: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Une erreur s est produite lors du changement du mot de passe')),
        );
      }
    }
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscureText, VoidCallback toggleVisibility, {String? Function(String?)? validator}) {
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
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: toggleVisibility,
          ),
        ),
        validator: validator ?? (value) => value!.isEmpty ? 'Ce champ est obligatoire' : null,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPasswordField(
                  'Current Password',
                  _currentPasswordController,
                  _obscureCurrentPassword,
                  () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                ),
                _buildPasswordField(
                  'New Password',
                  _newPasswordController,
                  _obscureNewPassword,
                  () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
                _buildPasswordField(
                  'Confirm New Password',
                  _confirmPasswordController,
                  _obscureConfirmPassword,
                  () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (value) {
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Changer le mot de passe'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}