import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';


class AdminProfileScreen extends StatefulWidget {
  final int id_admin;

  const AdminProfileScreen({super.key, required this.id_admin});

  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  Map<String, dynamic> _adminData = {};
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAdminInfo();
  }

  Future<void> _fetchAdminInfo() async {
    try {
      final response = await http.get(
        Uri.parse(Environment.getadminprofile(widget.id_admin)),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _adminData = Map<String, dynamic>.from(data['data']);
            _passwordController.text = _adminData['mot_de_passe'] ?? '';
          });
        } else {
          print('API returned success: false. Message: ${data['message']}');
        }
      } else {
        print('Failed to load admin data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching admin info: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final response = await http.post(
          Uri.parse(Environment.updateadminprofile()),
          body: {
            'id_admin': widget.id_admin.toString(),
            'nom': _adminData['nom'] ?? '',
            'prenom': _adminData['prenom'] ?? '',
            'adresse_email': _adminData['adresse_email'] ?? '',
            'mot_de_passe': _passwordController.text,
          },
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          try {
            var data = json.decode(response.body);
            if (data['success']) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
              setState(() {
                _adminData = Map<String, dynamic>.from(data['data']);
                _passwordController.text = _adminData['mot_de_passe'] ?? '';
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update profile: ${data['message']}')),
              );
            }
          } catch (e) {
            print('Error decoding JSON: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('An error occurred while processing the server response')),
            );
          }
        } else {
          print('Failed to update profile. Status code: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile. Server returned an error.')),
          );
        }
      } catch (e, stackTrace) {
        print('Error updating profile: $e');
        print('Stack trace: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred while updating the profile')),
        );
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
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) => value!.isEmpty ? 'Please enter your last name' : null,
                      onSaved: (value) => _adminData['nom'] = value,
                    ),
                    TextFormField(
                      initialValue: _adminData['prenom'],
                      decoration: const InputDecoration(labelText: 'First Name'),
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
                        labelText: 'Password',
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
                      validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5A90),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Update Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}