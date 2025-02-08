import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

class ViewAppointmentsScreen extends StatefulWidget {
  const ViewAppointmentsScreen({super.key});

  @override
  _ViewAppointmentsScreenState createState() => _ViewAppointmentsScreenState();
}

class _ViewAppointmentsScreenState extends State<ViewAppointmentsScreen> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String _currentStatus = 'accepte';

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/view_appointments.php?status=$_currentStatus'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _appointments = data['appointments'];
            _isLoading = false;
          });
        } else {
          _showErrorDialog('Failed to load appointments');
        }
      } else {
        _showErrorDialog('Server error');
      }
    } catch (e) {
      _showErrorDialog('Network error: $e');
    }
  }
  Future<void> _completeAppointment(int appointmentId) async {
  try {
    final response = await http.post(
      Uri.parse(Environment.completeAppointment()),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'appointment_id': appointmentId}),
    );

    final data = json.decode(response.body);
    if (data['success']) {
      // Refresh the appointments list
      _fetchAppointments();
      _showSuccessDialog('Appointment completed successfully');
    } else {
      _showErrorDialog(data['message'] ?? 'Failed to complete appointment');
    }
  } catch (e) {
    _showErrorDialog('Network error: $e');
  }
}
 void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Okay'),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Okay'),
          )
        ],
      ),
    );
  }

   Widget _buildStatusButton(String status, String label) {
    bool isSelected = _currentStatus == status;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentStatus = status;
        });
        _fetchAppointments();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.deepPurple : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendez-vous'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusButton('accepte', 'Accepted'),
                _buildStatusButton('attente_completion', 'Pending'),
                _buildStatusButton('complete', 'Completed'),
              ],
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _appointments.isEmpty
                  ? const Center(child: Text('No appointments found'))
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = _appointments[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: ListTile(
                              title: Text(
                                '${appointment['patient_name']} - ${appointment['service_name']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Doctor: ${appointment['doctor_name']}'),
                                  Text(
                                      'Date: ${appointment['date']}'),
                                ],
                              ),
                              trailing: _currentStatus == 'attente_completion'
                                  ? ElevatedButton(
                                      onPressed: () => _completeAppointment(
                                          appointment['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('Completer'),
                                    )
                                  : Text(
                                      '${appointment['price']} DA',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                    ),
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