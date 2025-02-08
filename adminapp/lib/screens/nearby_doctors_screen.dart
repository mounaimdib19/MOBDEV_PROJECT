import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

class NearbyDoctorsScreen extends StatefulWidget {
  final int requestId;
  final double patientLat;
  final double patientLon;

  const NearbyDoctorsScreen({
    super.key,
    required this.requestId,
    required this.patientLat,
    required this.patientLon,
  });

  @override
  _NearbyDoctorsScreenState createState() => _NearbyDoctorsScreenState();
}

class _NearbyDoctorsScreenState extends State<NearbyDoctorsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _doctors = [];
  String? _error;
  Map<String, dynamic>? _requestInfo;

  @override
  void initState() {
    super.initState();
    _fetchNearbyDoctors();
  }

  Future<void> _fetchNearbyDoctors() async {
    try {
      final response = await http.get(
        Uri.parse(
          Environment.searchNearbyDoctors(
            requestId: widget.requestId,
            patientLat: widget.patientLat,
            patientLon: widget.patientLon,
          ),
        ),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        setState(() {
          _doctors = List<Map<String, dynamic>>.from(data['doctors']);
          _requestInfo = data['request'];
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = data['message'] ?? 'Failed to fetch doctors';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _assignDoctor(int doctorId) async {
    if (doctorId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid doctor ID: must be positive')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Perform API call
      final response = await http.post(
        Uri.parse(Environment.assignDoctor()),
        body: {
          'requestId': widget.requestId.toString(),
          'doctorId': doctorId.toString(),
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      Navigator.of(context).pop();

      final data = json.decode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Médecin assigné avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Impossible d attribuer un médecin'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: doctor['photo'] != null
                      ? NetworkImage(Environment.getProfileImageUrl(doctor['photo']))
                      : null,
                  child: doctor['photo'] == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${doctor['distance']} km away',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        doctor['phone'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _assignDoctor(doctor['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Affecter un médecin',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Médecins à proximité'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    if (_requestInfo != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey[100],
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline),
                            const SizedBox(width: 8),
                            Text(
                              'Patient: ${_requestInfo!['patient_phone']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _doctors.isEmpty
                          ? const Center(
                              child: Text('Aucun médecin trouvé dans un rayon de 10 km'),
                            )
                          : ListView.builder(
                              itemCount: _doctors.length,
                              itemBuilder: (context, index) =>
                                  _buildDoctorCard(_doctors[index]),
                            ),
                    ),
                  ],
                ),
    );
  }
}