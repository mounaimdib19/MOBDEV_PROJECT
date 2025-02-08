import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'bottom_nav_bar.dart';
import 'book_appointment_screen.dart';
import '../config/environment.dart';

class WelcomeScreen extends StatefulWidget {
  final int id_patient;

  const WelcomeScreen({super.key, required this.id_patient});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentIndex = 0;
  bool _isRequestPending = false;

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 18 || hour < 4) {
      return 'bienvenue à Emassaha';
    } else {
      return 'bienvenue à Emassaha';
    }
  }

  Future<void> _submitAssistanceRequest(BuildContext context) async {
  try {
    final phoneNumber = await _getPatientPhoneNumber();

    if (phoneNumber != null) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmer la demande d\'assistance'),
            content: const Text('Vous souhaitez soumettre une demande d\'assistance ? Un assistant vous appellera sous peu.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Confirmer'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        final response = await http.post(
          Uri.parse(Environment.submitAssistanceRequest),
          body: {
            'phone_number': phoneNumber,
            'status': 'pending'
          },
        );

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          
          if (result['success']) {
            setState(() {
              _isRequestPending = true;
            });

            // Wait for 2 seconds to ensure DB is updated
            await Future.delayed(const Duration(seconds: 2));
            
            // Trigger notification dispatch
            final notifyResponse = await http.get(
              Uri.parse(Environment.fetchAssistanceRequests),
            );

            if (notifyResponse.statusCode == 200) {
              final notifyResult = json.decode(notifyResponse.body);
              
              if (notifyResult['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demande soumise avec succès')),
                );
              } else {
                print('Warning: Notification dispatch failed: ${notifyResult['message']}');
                // Still show success message since the request was submitted
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demande soumise avec succès')),
                );
              }
            } else {
              print('Warning: Failed to trigger notifications');
              // Still show success message since the request was submitted
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demande soumise avec succès')),
              );
            }
          } else {
            throw Exception('Failed to submit request: ${result['message']}');
          }
        } else {
          throw Exception('Error connecting to the server');
        }
      }
    }
  } catch (e) {
    print('Error in _submitAssistanceRequest: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  }
}

  Future<String?> _getPatientPhoneNumber() async {
    try {
      final response = await http.get(
        Uri.parse(Environment.getPatientPhoneNumber(widget.id_patient)),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          return result['phone_number'].toString();
        } else {
          throw Exception('Failed to fetch phone number: ${result['message']}');
        }
      } else {
        throw Exception('Error connecting to the server');
      }
    } catch (e) {
      print('Error fetching patient phone number: $e');
      rethrow;
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.25, // Reduced height
              width: double.infinity,
              child: CustomPaint(
                painter: TopShapePainter(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,  // Slightly smaller avatar
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prendre un rendez-vous',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 160, // Reduced height
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue[400]!, Colors.blue[800]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -50,
                          left: -50,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30,
                          right: -30,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'docteur/ infirmier/ Gardes malades à domicile',
                                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookAppointmentScreen(id_patient: widget.id_patient)),
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.blue[800],
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
  ),
  child: const Text(
    'Réservez maintenant',
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
),
                                  ],
                                ),
                              ),
                              Image.asset(
                                'assets/images/appointment.png',
                                width: 80,
                                height: 80,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Assistance téléphonique',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[800]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 160, // Reduced height
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.red[400]!, Colors.red[800]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -50,
                          left: -50,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30,
                          right: -30,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Assistance Medicale',
                                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
  onPressed: () => _submitAssistanceRequest(context),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.red[800],
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
  ),
  child: const Text(
    'Demande d\'assistance',
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
),
                                  ],
                                ),
                              ),
                              Image.asset(
                                'assets/images/Call.png',
                                width: 80,
                                height: 80,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
        id_patient: widget.id_patient,
      ),
    );
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