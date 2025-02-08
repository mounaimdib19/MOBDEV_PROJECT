import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import '../services/admin_session_manager.dart';

class AdminProfileScreen extends StatefulWidget {
  final int idAdmin;

  const AdminProfileScreen({super.key, required this.idAdmin});

  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  Map<String, dynamic> _adminData = {};
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordModified = false;

  @override
  void initState() {
    super.initState();
    _fetchAdminInfo();
  }

  Future<void> _fetchAdminInfo() async {
    try {
      final response = await http.get(
        Uri.parse(Environment.getadminprofile(widget.idAdmin)),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _adminData = Map<String, dynamic>.from(data['data']);
            // Don't set password in the text controller
            _passwordController.clear();
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Failed to load profile data')),
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching admin info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading profile data')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final response = await http.post(
          Uri.parse(Environment.updateadminprofile()),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'idAdmin': widget.idAdmin,
            'nom': _adminData['nom'],
            'prenom': _adminData['prenom'],
            'adresse_email': _adminData['adresse_email'],
            // Only send password if it was modified
            if (_isPasswordModified) 'mot_de_passe': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          if (data['success']) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(data['message'] ?? 'Failed to update profile')),
              );
            }
          }
        }
      } catch (e) {
        print('Error updating profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error updating profile')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF1B5A90),
      ),
      body: _adminData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: _adminData['nom'],
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (value) => value!.isEmpty ? 'Please enter your last name' : null,
                      onSaved: (value) => _adminData['nom'] = value,
                    ),
                    TextFormField(
                      initialValue: _adminData['prenom'],
                      decoration: const InputDecoration(labelText: 'Prenom'),
                      validator: (value) => value!.isEmpty ? 'Please enter your first name' : null,
                      onSaved: (value) => _adminData['prenom'] = value,
                    ),
                    TextFormField(
                      initialValue: _adminData['adresse_email'],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
                      onSaved: (value) => _adminData['adresse_email'] = value,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe (laisser vide pour ne pas changer)',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      onChanged: (value) {
                        setState(() {
                          _isPasswordModified = value.isNotEmpty;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5A90),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text('Mettre a jour Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}