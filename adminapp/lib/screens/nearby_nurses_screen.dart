import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

class NearbyNursesScreen extends StatefulWidget {
  final int requestId;
  final double patientLat;
  final double patientLon;
  final int serviceTypeId;

  const NearbyNursesScreen({
    super.key,
    required this.requestId,
    required this.patientLat,
    required this.patientLon,
    required this.serviceTypeId,
  });

  @override
  _NearbyNursesScreenState createState() => _NearbyNursesScreenState();
}

class _NearbyNursesScreenState extends State<NearbyNursesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _nurses = [];
  String? _error;
  Map<String, dynamic>? _requestInfo;

  @override
  void initState() {
    super.initState();
    _fetchNearbyNurses();
  }

Future<void> _fetchNearbyNurses() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final response = await http.get(
      Uri.parse(
        Environment.searchNearbyNurses(
          requestId: widget.requestId,
          patientLat: widget.patientLat,
          patientLon: widget.patientLon,
          serviceTypeId: widget.serviceTypeId,
        ),
      ),
    );

    print('Raw response: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    final Map<String, dynamic> data = json.decode(response.body);

    if (!data.containsKey('success')) {
      throw Exception('Invalid response format');
    }

    if (data['success'] == true) {
      final List<dynamic> nursesList = data['nurses'] ?? [];
      final requestInfo = data['request'];

      setState(() {
        _nurses = nursesList.map((nurse) => Map<String, dynamic>.from(nurse)).toList();
        _requestInfo = requestInfo != null ? Map<String, dynamic>.from(requestInfo) : null;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = data['message']?.toString() ?? 'Unknown error occurred';
        _isLoading = false;
      });
    }
  } catch (e) {
    print('Error fetching nurses: $e');
    setState(() {
      _error = 'Error: ${e.toString()}';
      _isLoading = false;
    });
  }
}


  Future<void> _assignNurse(int nurseId) async {
    if (nurseId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid nurse ID: must be positive')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await http.post(
        Uri.parse(Environment.assignNurse()),
         body: {
   'requestId': widget.requestId.toString(),
  'id_doc': nurseId.toString(),
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
            content: Text('Infirmière affectée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Impossible d affecter une infirmière'),
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

  Widget _buildNurseCard(Map<String, dynamic> nurse) {
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
                  backgroundImage: nurse['photo'] != null
                      ? NetworkImage(Environment.getProfileImageUrl(nurse['photo']))
                      : null,
                  child: nurse['photo'] == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nurse['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${nurse['distance']} km away',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        nurse['phone'],
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
                onPressed: () => _assignNurse(nurse['id_doc']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Assign Nurse',
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
        title: const Text('Nearby Nurses'),
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
                      child: _nurses.isEmpty
                          ? const Center(
                              child: Text('Aucune infirmière trouvée dans un rayon de 10 km pour ce service'),
                            )
                          : ListView.builder(
                              itemCount: _nurses.length,
                              itemBuilder: (context, index) =>
                                  _buildNurseCard(_nurses[index]),
                            ),
                    ),
                  ],
                ),
    );
  }
}