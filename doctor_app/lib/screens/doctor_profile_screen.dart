import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'doctor_welcome_screen.dart';
import 'doctor_bottom_nav_bar.dart';
import '../config/environment.dart';
import 'doctor_change_password_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  final int id_doc;

  const DoctorProfileScreen({super.key, required this.id_doc});

  @override
  _DoctorProfileScreenState createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Map<String, dynamic> _doctorData = {};
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctorInfo();
  }

  Future<void> _fetchDoctorInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(Environment.getDoctorProfile(widget.id_doc)),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _doctorData = Map<String, dynamic>.from(data['doctor']);
            _doctorData.forEach((key, value) {
              _doctorData[key] = value?.toString() ?? '';
            });
            _doctorData['id_doc'] = widget.id_doc.toString();
          });
        } else {
          print('API returned success: false. Message: ${data['message']}');
          _showErrorDialog('Failed to load profile data');
        }
      } else {
        print('Failed to load doctor data. Status code: ${response.statusCode}');
        _showErrorDialog('Failed to load profile data');
      }
    } catch (e) {
      print('Error fetching doctor info: $e');
      _showErrorDialog('An error occurred while fetching profile data');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse(Environment.updateDoctorProfile),
          body: {
            'id_doc': widget.id_doc.toString(),
            'nom': _doctorData['nom'] ?? '',
            'prenom': _doctorData['prenom'] ?? '',
            'adresse': _doctorData['adresse'] ?? '',
            'id_wilaya': _doctorData['id_wilaya']?.toString() ?? '',
            'id_commune': _doctorData['id_commune']?.toString() ?? '',
            'adresse_email': _doctorData['adresse_email'] ?? '',
            'numero_telephone': _doctorData['numero_telephone'] ?? '',
            'Latitude': _doctorData['Latitude']?.toString() ?? '',
            'longitude': _doctorData['longitude']?.toString() ?? '',
            'status': _doctorData['status'] ?? '',
          },
        );

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          if (data['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
            _fetchDoctorInfo();
          } else {
            _showErrorDialog('Failed to update profile: ${data['message']}');
          }
        } else {
          _showErrorDialog('Failed to update profile. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error updating profile: $e');
        _showErrorDialog('An error occurred while updating the profile');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorChangePasswordScreen(id_doc: widget.id_doc),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DoctorWelcomeScreen(id_doc: widget.id_doc.toString())),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            initialValue: _doctorData['nom'],
                            decoration: const InputDecoration(labelText: 'Nom'),
                            validator: (value) => value!.isEmpty ? 'Please enter your last name' : null,
                            onSaved: (value) => _doctorData['nom'] = value,
                          ),
                          TextFormField(
                            initialValue: _doctorData['prenom'],
                            decoration: const InputDecoration(labelText: 'Prénom'),
                            validator: (value) => value!.isEmpty ? 'Please enter your first name' : null,
                            onSaved: (value) => _doctorData['prenom'] = value,
                          ),
                          TextFormField(
                            initialValue: _doctorData['adresse_email'],
                            decoration: const InputDecoration(labelText: 'Email'),
                            validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
                            onSaved: (value) => _doctorData['adresse_email'] = value,
                          ),
                          TextFormField(
                            initialValue: _doctorData['numero_telephone'],
                            decoration: const InputDecoration(labelText: 'Phone Number'),
                            keyboardType: TextInputType.phone,
                            validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
                            onSaved: (value) => _doctorData['numero_telephone'] = value,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 41, 192, 76),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            child: const Text('Mettre à jour le profil'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(thickness: 1),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _navigateToChangePassword,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Change Password'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                        side: const BorderSide(color: Color.fromARGB(255, 12, 160, 31)),
                        foregroundColor: const Color.fromARGB(255, 41, 217, 109),
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: DoctorBottomNavBar(
          currentIndex: 2,
          id_doc: widget.id_doc.toString(),
        ),
      ),
    );
  }
}