import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'bottom_nav_bar.dart';
import '../config/environment.dart';


class PatientAppointmentsScreen extends StatefulWidget {
  final String id_patient;

  const PatientAppointmentsScreen({super.key, required this.id_patient});

  @override
  _PatientAppointmentsScreenState createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  List<Map<String, dynamic>> _appointments = [];
  int _currentIndex = 1;
  bool _showingCompleted = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
  final endpoint = _showingCompleted
      ? Environment.getPatientCompletedAppointments(widget.id_patient)
      : Environment.getPatientPendingAcceptedAppointments(widget.id_patient);
  
  try {
    final response = await http.get(
      Uri.parse(endpoint),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        if (data['success']) {
          _appointments = List<Map<String, dynamic>>.from(data['appointments']);
        } else {
          _appointments = []; // Clear the list if no appointments are found
        }
      });
    } else {
      print('API request failed with status: ${response.statusCode}');
      setState(() {
        _appointments = []; // Clear the list on error
      });
    }
  } catch (e) {
    print('Error fetching appointments: $e');
    setState(() {
      _appointments = []; // Clear the list on error
    });
  }
}

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Handle navigation here if needed
  }

  Future<void> _cancelAppointment(int idRendezVous) async {
    try {
      final response = await http.post(
        Uri.parse(Environment.cancelAppointment),
        body: {
          'id_rendez_vous': idRendezVous.toString(),
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment cancelled successfully')),
          );
          _fetchAppointments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel appointment: ${data['message']}')),
          );
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error cancelling appointment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.25,
            width: double.infinity,
            child: CustomPaint(
              painter: TopShapePainter(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showingCompleted ? 'Rendez-vous terminés' : 'Rendez-vous acceptés',
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildToggleButton('Completed', _showingCompleted, () {
                        setState(() {
                          _showingCompleted = true;
                        });
                        _fetchAppointments();
                      }),
                      _buildToggleButton('Accepted', !_showingCompleted, () {
                        setState(() {
                          _showingCompleted = false;
                        });
                        _fetchAppointments();
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _appointments.isEmpty
                ? Center(
                    child: Text(
                      'Pas de rendez-vous ${_showingCompleted ? 'complété' : 'en attente/accepté'} trouvés',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = _appointments[index];
                      return _buildAppointmentCard(appointment);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
        id_patient: int.parse(widget.id_patient),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isActive, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF2ECC71) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: isActive ? 5 : 2,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dr. ${appointment['doctor_nom']} ${appointment['doctor_prenom']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5A90)),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.calendar_today, 'Date: ${appointment['date_heure_rendez_vous']}'),
              if (_showingCompleted)
                _buildInfoRow(Icons.attach_money, 'Prix: ${appointment['montant'] ?? 'N/A'} DZD'),
              if (!_showingCompleted)
                _buildInfoRow(Icons.info_outline, 'Status: ${appointment['statut']}'),
              if (!_showingCompleted)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _cancelAppointment(appointment['id_rendez_vous']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
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