import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import 'admin_doctor_appointments_screen.dart';

class ViewDoctorsScreen extends StatefulWidget {
  final String type;

  const ViewDoctorsScreen({super.key, required this.type});

  @override
  _ViewDoctorsScreenState createState() => _ViewDoctorsScreenState();
}

class _ViewDoctorsScreenState extends State<ViewDoctorsScreen> {
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _banFilter = 'all'; // 'all', 'active', 'banned'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _toggleBanStatus(int doctorId) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/ban_doctor.php'),
        body: json.encode({'id_doc': doctorId}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          await _fetchDoctors();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['est_banni'] 
                ? 'Doctor has been banned' 
                : 'Doctor has been unbanned'),
              backgroundColor: data['est_banni'] ? Colors.red : Colors.green,
            ),
          );
        } else {
          _showError('Failed to update ban status');
        }
      } else {
        _showError('Failed to connect to server');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${Environment.getdoctors(widget.type)}&ban_status=$_banFilter'),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _doctors = List<Map<String, dynamic>>.from(data['doctors']);
            _isLoading = false;
          });
        } else {
          _showError('API returned error: ${data['message']}');
        }
      } else {
        _showError('Failed to fetch doctors');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    if (_searchQuery.isEmpty) return _doctors;
    return _doctors.where((doctor) {
      final searchLower = _searchQuery.toLowerCase();
      final name = '${doctor['nom']} ${doctor['prenom']}'.toLowerCase();
      final email = doctor['adresse_email'].toString().toLowerCase();
      final phone = doctor['numero_telephone']?.toString().toLowerCase() ?? '';
      final address = '${doctor['adresse']} ${doctor['commune']} ${doctor['wilaya']}'.toLowerCase();
      
      return name.contains(searchLower) || 
             email.contains(searchLower) || 
             phone.contains(searchLower) ||
             address.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Afficher ${widget.type.capitalize()}s'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, phone, or address...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _filterButton('Tous les docteurs', 'all'),
        const SizedBox(width: 8),
        _filterButton('Docteurs actifs', 'active'),
        const SizedBox(width: 8),
        _filterButton('Docteurs Bannis', 'banned'),
      ],
    ),
  ),
),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDoctors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No doctors found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchDoctors,
                        child: ListView.builder(
                          itemCount: _filteredDoctors.length,
                          itemBuilder: (context, index) {
                            var doctor = _filteredDoctors[index];
                            bool isBanned = doctor['est_banni'].toString() == '1';

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 2,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminDoctorAppointmentsScreen(
                                        doctorData: doctor,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: isBanned ? Colors.red : Colors.indigo,
                                            child: Text(
                                              '${doctor['nom'][0]}${doctor['prenom'][0]}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${doctor['nom']} ${doctor['prenom']}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (doctor['numero_telephone'] != null)
                                                  Text(
                                                    'Phone: ${doctor['numero_telephone']}',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                Text(
                                                  doctor['adresse_email'],
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap( // Changed from Row to Wrap
                                              spacing: 8, // Add spacing between wrapped items
                                              runSpacing: 4, // Add spacing between wrapped lines
                                              children: [
                                                Text(
                                                  'Appointments: ${doctor['appointments_count']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  'Earnings: ${doctor['total_earnings']} DZD',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${doctor['adresse']}, ${doctor['commune']}, ${doctor['wilaya']}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis, // Add overflow handling for address
                                              maxLines: 2, // Limit to 2 lines
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => _toggleBanStatus(int.parse(doctor['id_doc'].toString())),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isBanned ? Colors.green : Colors.red,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          child: Text(
                                            isBanned ? 'DÉBANNIR CE DOCTEUR' : 'BANNIR CE DOCTEUR',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String text, String filter) {
    bool isSelected = _banFilter == filter;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _banFilter = filter;
        });
        _fetchDoctors();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.indigo : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}