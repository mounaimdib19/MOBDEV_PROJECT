import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'doctor_welcome_screen.dart';
import '../config/environment.dart';
import '../services/session_manager.dart';
class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  _DoctorLoginScreenState createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    if (await SessionManager.isLoggedIn()) {
      String? doctorId = await SessionManager.getDoctorId();
      if (doctorId != null && mounted) {  // Add mounted check
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DoctorWelcomeScreen(id_doc: doctorId),
          ),
        );
      }
    }
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

  Future<void> _loginAsDoctor() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final response = await http.post(
          Uri.parse(Environment.doctorLogin),
          body: {
            'email': _email,
            'password': _password,
          },
        );

        if (!mounted) return;  // Add mounted check before using context

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          if (result['success']) {
            // Store session data
            await SessionManager.createSession(
              result['id_doc'].toString(),
              _email,
            );

            if (!mounted) return;  // Add another mounted check after async operation

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Doctor login successful!')),
            );
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DoctorWelcomeScreen(
                  id_doc: result['id_doc'].toString(),
                ),
              ),
            );
          } else {
            _showErrorDialog(result['message'] ?? 'Invalid credentials');
          }
        } else {
          _showErrorDialog('Error connecting to the server');
        }
      } catch (e) {
        if (!mounted) return;  // Add mounted check
        _showErrorDialog('Network error: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.green.withOpacity(0.3),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Doctor Login',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextFormField(
                            'Email',
                            (value) => _email = value!,
                            keyboardType: TextInputType.emailAddress
                          ),
                          _buildTextFormField(
                            'Password',
                            (value) => _password = value!,
                            obscureText: true
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loginAsDoctor,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15
                              ),
                              textStyle: const TextStyle(fontSize: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
  'Si vous n\'avez pas de compte, contactez emassaha@gmail.com',
  style: TextStyle(
    color: Colors.black87,  // Changed from grey to a darker color
    fontSize: 16,          // Increased from 14
    fontWeight: FontWeight.w500,  // Added medium font weight
  ),
  textAlign: TextAlign.center,
),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField(
    String label,
    Function(String?) onSaved, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: (value) => value!.isEmpty ? 'Veuillez entrer votre $label' : null,
        onSaved: onSaved,
      ),
    );
  }
}