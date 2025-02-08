import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'welcome_screen.dart';
import '../config/environment.dart';
import '../services/session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _phoneNumber = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    setState(() => _isLoading = true);
    final session = await SessionManager.getSession();
    setState(() => _isLoading = false);
    
    if (session != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(id_patient: session['patientId']),
        ),
      );
    }
  }

Future<void> _login() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(Environment.patientLogin),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'numero_telephone': _phoneNumber},
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          if (result['success'] == true && mounted) {
            await SessionManager.saveSession(_phoneNumber, result['id_patient']);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => WelcomeScreen(id_patient: result['id_patient']),
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Login failed')),
            );
          }
        } catch (e) {
          print('JSON decode error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Server returned invalid response format'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Network error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection error. Please check your internet connection'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
}


  Future<void> _showAssistanceMedicaleDialog() async {
    final TextEditingController phoneController = TextEditingController();
    final GlobalKey<FormState> assistanceFormKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF3498DB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'Assistance Medicale',
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          content: Form(
            key: assistanceFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Besoin d\'aide médicale ?',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    hintText: "07XXXXXXXX",
                    labelText: 'Votre numero de telephone',
                    prefixIcon: const Icon(
                      Icons.phone,
                      color: Color(0xFF3498DB),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: _validatePhone,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text('Soumettre'),
              onPressed: () {
                if (assistanceFormKey.currentState!.validate()) {
                  _submitAssistanceRequest(phoneController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Le numéro doit contenir uniquement des chiffres';
    }
    if (value.length != 10) {
      return 'Le numéro doit contenir 10 chiffres';
    }
    if (!value.startsWith('07') && !value.startsWith('06') && !value.startsWith('05')) {
      return 'Le numéro doit commencer par 07, 06 ou 05';
    }
    return null;
  }

 Future<void> _submitAssistanceRequest(String phoneNumber) async {
  try {
    final response = await http.post(
      Uri.parse(Environment.submitAssistanceRequest),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'phone_number': phoneNumber},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      try {
        final result = json.decode(response.body);
        if (result['success']) {
          // Success notification
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demande d\'assistance envoyée avec succès')),
          );
          
          // Optional: Trigger notification dispatch
          try {
            await http.get(Uri.parse(Environment.fetchAssistanceRequests));
          } catch (e) {
            print('Warning: Failed to trigger notifications: $e');
            // Don't show error to user since main request succeeded
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to submit request')),
          );
        }
      } catch (e) {
        print('JSON decode error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server returned invalid response format')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server error: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Network error in assistance request: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error. Please check your internet connection')),
      );
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
          Container(color: Colors.black.withOpacity(0.5)),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Bienvenue!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Votre numero de telephone',
                            hintText: 'XXXXXXXXXX',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          validator: _validatePhone,
                          onSaved: (value) => _phoneNumber = value!,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3498DB),
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Entrez'),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _showAssistanceMedicaleDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE74C3C),
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Assistance Medicale'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}