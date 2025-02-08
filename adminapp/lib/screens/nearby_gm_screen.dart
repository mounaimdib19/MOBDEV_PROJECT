import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

class NearbyGardeMaladesScreen extends StatefulWidget {
  final int requestId;
  final double patientLat;
  final double patientLon;

  const NearbyGardeMaladesScreen({
    super.key,
    required this.requestId,
    required this.patientLat,
    required this.patientLon,
  });

  @override
  _NearbyGardeMaladesScreenState createState() => _NearbyGardeMaladesScreenState();
}

class _NearbyGardeMaladesScreenState extends State<NearbyGardeMaladesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _gardeMalades = [];
  String? _error;
  Map<String, dynamic>? _requestInfo;

  @override
  void initState() {
    super.initState();
    _fetchNearbyGardeMalades();
  }

  Future<void> _fetchNearbyGardeMalades() async {
    try {
      final response = await http.get(
        Uri.parse(
          Environment.searchNearbyGardeMalades(
            requestId: widget.requestId,
            patientLat: widget.patientLat,
            patientLon: widget.patientLon,
          ),
        ),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        setState(() {
          _gardeMalades = List<Map<String, dynamic>>.from(data['garde_malades']);
          _requestInfo = data['request'];
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = data['message'] ?? 'Failed to fetch garde malades';
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

  Future<void> _assignGardeMalade(int gardeMaladeId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await http.post(
        Uri.parse(Environment.assignGardeMalade()),
        body: {
          'requestId': widget.requestId.toString(),
          'gardeMaladeId': gardeMaladeId.toString(),
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
            content: Text('Garde malade assigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to assign garde malade'),
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

  Widget _buildGardeMaladeCard(Map<String, dynamic> gardeMalade) {
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
                  backgroundImage: gardeMalade['photo'] != null
                      ? NetworkImage(Environment.getProfileImageUrl(gardeMalade['photo']))
                      : null,
                  child: gardeMalade['photo'] == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gardeMalade['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${gardeMalade['distance']} km away',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        gardeMalade['phone'],
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
                onPressed: () => _assignGardeMalade(gardeMalade['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Assigner Garde Malade',
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
        title: const Text('Garde Malades À proximité'),
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
                      child: _gardeMalades.isEmpty
                          ? const Center(
                              child: Text('Aucun garde malade trouvé dans un rayon de 10 km'),
                            )
                          : ListView.builder(
                              itemCount: _gardeMalades.length,
                              itemBuilder: (context, index) =>
                                  _buildGardeMaladeCard(_gardeMalades[index]),
                            ),
                    ),
                  ],
                ),
    );
  }
}