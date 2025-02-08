import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'bottom_nav_bar.dart';
import 'book_doctor_appointment_screen.dart';
import 'book_garde_malade_screen.dart';
import 'services_screen.dart';
import '../config/environment.dart';

class BookAppointmentScreen extends StatelessWidget {
  final int id_patient;
  const BookAppointmentScreen({super.key, required this.id_patient});

  Future<void> _showSuccessDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Demande Envoyée',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Un assistant vous appellera sous peu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitAssistanceRequest(BuildContext context) async {
  try {
    final phoneNumber = await _getPatientPhoneNumber();

    if (phoneNumber != null) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmer la demande d\'assistance téléphonique'),
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
        // Submit the assistance request
        final submitResponse = await http.post(
          Uri.parse(Environment.submitAssistanceRequest),
          body: {
            'phone_number': phoneNumber,
          },
        );

        if (submitResponse.statusCode == 200) {
          final submitResult = json.decode(submitResponse.body);
          
          if (submitResult['success']) {
            // Wait for 2 seconds to ensure DB is updated
            await Future.delayed(const Duration(seconds: 2));
            
            // Trigger notification dispatch by calling fetch_assistance_requests.php
            try {
              final assistanceNotifyResponse = await http.get(
                Uri.parse(Environment.fetchAssistanceRequests),
              ).timeout(
                const Duration(seconds: 10),
              );

              if (assistanceNotifyResponse.statusCode == 200) {
                final assistanceNotifyResult = json.decode(assistanceNotifyResponse.body);
                
                if (!assistanceNotifyResult['success']) {
                  print('Warning: Assistance notification dispatch failed: ${assistanceNotifyResult['message']}');
                }
              }

              // Call admin notifications endpoint
              try {
                await http.get(
                  Uri.parse(Environment.adminNotifications),
                ).timeout(
                  const Duration(seconds: 10),
                );
              } catch (e) {
                // Even if admin notification fails, we don't want to show an error to the user
                // as their request was still successful
                debugPrint('Admin notification failed: $e');
              }

              await _showSuccessDialog(context);
            } catch (e) {
              print('Warning: Failed to trigger notifications: $e');
              // Still show success dialog since the request was submitted
              await _showSuccessDialog(context);
            }
          } else {
            throw Exception('Failed to submit request: ${submitResult['message']}');
          }
        } else {
          throw Exception('Erreur de connexion au serveur');
        }
      }
    } else {
      throw Exception('Impossible de récupérer le numéro de téléphone');
    }
  } catch (e) {
    print('Error in _submitAssistanceRequest: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Une erreur est survenue: $e')),
    );
  }
}

  Future<String?> _getPatientPhoneNumber() async {
    try {
      final response = await http.get(
        Uri.parse(Environment.getPatientPhoneNumber(id_patient)),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          return result['phone_number'].toString();
        } else {
          throw Exception('Impossible de récupérer le numéro: ${result['message']}');
        }
      } else {
        throw Exception('Erreur de connexion au serveur');
      }
    } catch (e) {
      print('Error fetching patient phone number: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('Choisissez votre service'),
                    const SizedBox(height: 16),
                    _buildAppointmentBox(
                      context,
                      'Médecin à domicile',
                      'assets/images/doctor1.png',
                      const Color(0xFF5B9BD5),
                      const Color.fromARGB(255, 37, 114, 201),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDoctorAppointmentScreen(id_patient: id_patient),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAppointmentBox(
                      context,
                      'Infirmier à domicile',
                      'assets/images/nurse.png',
                      const Color.fromARGB(255, 112, 207, 115),
                      const Color.fromARGB(255, 46, 170, 52),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServicesScreen(id_patient: id_patient),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAppointmentBox(
                      context,
                      'Garde Malade',
                      'assets/images/patient.png',
                      const Color(0xFFFFA726),
                      const Color(0xFFF57C00),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookGardeMaladeScreen(id_patient: id_patient),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAppointmentBox(
                      context,
                      'Assistance Téléphonique',
                      'assets/images/online_consultation.png',
                      const Color(0xFF9C27B0),
                      const Color(0xFF6A1B9A),
                      () => _submitAssistanceRequest(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          // Handle navigation here if needed
        },
        id_patient: id_patient,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2, // Reduced from 0.25 to 0.2
      width: double.infinity,
      child: CustomPaint(
        painter: TopShapePainter(),
        child: const SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Prendre rendez-vous',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAppointmentBox(BuildContext context, String title, String iconPath, Color color1, Color color2, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color1, color2],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              left: -20,
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
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    iconPath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ],
        ),
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