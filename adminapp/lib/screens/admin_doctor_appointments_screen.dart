// admin_doctor_appointments_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../config/environment.dart';

class AdminDoctorAppointmentsScreen extends StatefulWidget {
  final Map<String, dynamic> doctorData;

  const AdminDoctorAppointmentsScreen({
    super.key, 
    required this.doctorData,
  });

  @override
  _AdminDoctorAppointmentsScreenState createState() => _AdminDoctorAppointmentsScreenState();
}

class _AdminDoctorAppointmentsScreenState extends State<AdminDoctorAppointmentsScreen> {
  final List<Map<String, dynamic>> _completedAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompletedAppointments();
  }

  Future<void> _fetchCompletedAppointments() async {
    try {
      final url = Uri.parse(
        '${Environment.apiUrl}/get_admin_doctor_appointments.php?id_doc=${widget.doctorData['id_doc']}'
      );
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
        setState(() => _isLoading = false);
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
    final totalEarnings = _completedAppointments.fold<double>(
      0,
      (sum, appointment) => sum + double.parse(appointment['montant'].toString())
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.doctorData['nom']} ${widget.doctorData['prenom']} - Appointments'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.indigo.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Appointments: ${_completedAppointments.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Total Earnings: ${totalEarnings.toStringAsFixed(2)} DZD',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _completedAppointments.isEmpty
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
                                'No completed appointments',
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
                              child: ListTile(
                                title: Text(
                                  '${appointment['patient_nom']} ${appointment['patient_prenom']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(appointment['date_heure_rendez_vous']),
                                    Text('Service: ${appointment['service_name']}'),
                                    Text(
                                      'Amount: ${appointment['montant']} DZD',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}