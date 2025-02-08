import 'package:flutter/material.dart';
import 'doctor_bottom_nav_bar.dart';
import 'doctor_welcome_screen.dart';
import '../config/environment.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DoctorCompletedAppointmentsScreen extends StatefulWidget {
  final String id_doc;

  const DoctorCompletedAppointmentsScreen({super.key, required this.id_doc});

  @override
  _DoctorCompletedAppointmentsScreenState createState() => _DoctorCompletedAppointmentsScreenState();
}

class _DoctorCompletedAppointmentsScreenState extends State<DoctorCompletedAppointmentsScreen> {
  final List<Map<String, dynamic>> _completedAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompletedAppointments();
  }

  Future<void> _fetchCompletedAppointments() async {
  try {
    final url = Uri.parse(Environment.getCompletedAppointments(widget.id_doc));
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> appointmentsData = json.decode(response.body);
      setState(() {
        _completedAppointments.clear();
        _completedAppointments.addAll(appointmentsData.map((appointment) => {
          'patient_nom': appointment['nom'] ?? 'Unknown',
          'patient_prenom': appointment['prenom'] ?? 'Unknown',
          'date_heure_rendez_vous': _formatDateTime(appointment['date_heure_rendez_vous'] ?? ''),
          'montant': appointment['montant']?.toString() ?? '0',
          'service_name': appointment['service_name'] ?? 'Unspecified Service', 
        }));
        _isLoading = false;
      });
    } else {
      // Handle non-200 status code
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load appointments: ${response.statusCode}')),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading appointments: $e')),
    );
  }
}

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('EEEE, MMM d, y • HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DoctorWelcomeScreen(id_doc: widget.id_doc)),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Rendez-vous terminés',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 42, 170, 70),
          automaticallyImplyLeading: false,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1B5A90),
                ),
              )
            : _completedAppointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun rendez-vous complété',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _completedAppointments.length,
                    itemBuilder: (context, index) {
                      final appointment = _completedAppointments[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color.fromARGB(255, 80, 196, 109).withOpacity(0.1),
                                    child: Text(
                                      '${appointment['patient_nom'][0]}${appointment['patient_prenom'][0]}',
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 13, 158, 33),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${appointment['patient_nom']} ${appointment['patient_prenom']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          appointment['date_heure_rendez_vous'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Display service type
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 62, 152, 76).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  appointment['service_name'] ?? 'Service not specified',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Payment amount
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 27, 144, 37).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.payments_outlined,
                                      size: 18,
                                      color: Color.fromARGB(255, 27, 144, 31),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${appointment['montant']} DZD',
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 27, 144, 35),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        bottomNavigationBar: DoctorBottomNavBar(
          currentIndex: 1,
          id_doc: widget.id_doc,
        ),
      ),
    );
  }
}