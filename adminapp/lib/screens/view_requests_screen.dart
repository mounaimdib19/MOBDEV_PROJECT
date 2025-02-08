import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/environment.dart';
import 'nearby_doctors_screen.dart';
import 'nearby_nurses_screen.dart';
import 'nearby_gm_screen.dart';

class ViewRequestsScreen extends StatefulWidget {
  const ViewRequestsScreen({super.key});

  @override
  _ViewRequestsScreenState createState() => _ViewRequestsScreenState();
}

class _ViewRequestsScreenState extends State<ViewRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  String _selectedType = 'all';
  String _selectedStatus = 'all';
  String _searchQuery = '';
  Map<String, int> _stats = {
    'total': 0,
    'doctor': 0,
    'nurse': 0,
    'garde_malade': 0,
    'assistant': 0,
  };
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    // Auto refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchRequests());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    try {
      final response = await http.get(
        Uri.parse(
          Environment.viewRequests(
            type: _selectedType,
            status: _selectedStatus,
            search: _searchQuery,
          ),
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            // Changed from 'requests' to 'appointments' to match PHP response
            _requests = List<Map<String, dynamic>>.from(data['appointments'] ?? []);
            _stats = Map<String, int>.from(data['summary'] ?? {
              'total': 0,
              'doctor': 0,
              'nurse': 0,
              'garde_malade': 0,
              'assistant': 0,
            });
          });
        } else {
          _showErrorDialog(data['message'] ?? 'Unknown error occurred');
        }
      } else {
        _showErrorDialog('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching requests: $e');
      _showErrorDialog('Failed to load requests: ${e.toString()}');
    }
  }

Future<void> _findProvider(dynamic requestId, String type, dynamic lat, dynamic lon, Map<String, dynamic> request) async {
  print("Full request data when finding nurse: $request"); // Add this debug line  // Helper function to convert requestId to String
  int? safeParseRequestId(dynamic value) {
    if (value == null) return null;
    
    if (value is int) return value;

    if (value is String) return int.tryParse(value);
    
    return null;
  }

  // Helper function to parse coordinates to double
  double? safeParseDouble(dynamic value) {
    if (value == null) return null;
    
    if (value is double) return value;
    
    if (value is String) {
      return double.tryParse(value);
    }
    
    if (value is int) {
      return value.toDouble();
    }
    
    return null;
  }

  // Safely convert requestId
  final int? parsedRequestId = safeParseRequestId(requestId);  
  // Validate requestId
  if (parsedRequestId == null) {
    _showErrorDialog('Invalid request ID');
    return;
  }
  
  // Safely convert coordinates
  final double? patientLat = safeParseDouble(lat);
  final double? patientLon = safeParseDouble(lon);
  
  // Validate coordinates
  if (patientLat == null || patientLon == null) {
    _showErrorDialog('Invalid location coordinates');
    return;
  }
  
  switch (type) {
    case 'doctor':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NearbyDoctorsScreen(
            requestId: parsedRequestId,
            patientLat: patientLat,
            patientLon: patientLon,
          ),
        ),
      );
      break;
      
    case 'nurse':
    
final serviceTypeId = request['id_service_type'];
      
      if (serviceTypeId == null) {
        _showErrorDialog('Service type not found for this request. Please ensure the request has a valid service type.');
        return;
      }
      
       Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NearbyNursesScreen(
            requestId: parsedRequestId,
            patientLat: patientLat,
            patientLon: patientLon,
            serviceTypeId: int.parse(serviceTypeId.toString()),
          ),
        ),
      );
      break;
      
    case 'garde_malade':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NearbyGardeMaladesScreen(
            requestId: parsedRequestId,
            patientLat: patientLat,
            patientLon: patientLon,
          ),
        ),
      );
      break;
      
    case 'assistant':
      _showErrorDialog('Assistant provider not implemented yet');
      break;
    
    default:
      _showErrorDialog('Unsupported provider type');
  }
}

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Provider Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Types')),
                DropdownMenuItem(value: 'doctor', child: Text('Doctors')),
                DropdownMenuItem(value: 'nurse', child: Text('Nurses')),
                DropdownMenuItem(value: 'garde_malade', child: Text('Garde Malades')),
                DropdownMenuItem(value: 'assistant', child: Text('Assistants')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  _fetchRequests();
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tous les statuts')),
                DropdownMenuItem(value: 'pending', child: Text('En attente')),
                DropdownMenuItem(value: 'assigned', child: Text('Assignée')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                  _fetchRequests();
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Recherche par numéro de téléphone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _fetchRequests();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatsCard(IconData icon, String title, int count) {
  return Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.indigo),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildRequestCard(Map<String, dynamic> request) {
  final bool isAssigned = request['assigned_provider_id'] != null;
  final String statusText = isAssigned ? 'Assigned' : 'Pending';
  final Color statusColor = isAssigned ? Colors.green : Colors.orange;

  // Add icon mapping for different request types
  final Map<String, IconData> typeIcons = {
    'doctor': Icons.medical_services,
    'nurse': Icons.healing,
    'garde_malade': Icons.volunteer_activism,
    'assistant': Icons.people,
  };

  // Capitalize first letter of request type for display
  String displayType = request['type']?.toString() ?? '';
  displayType = displayType.split('_').map((word) => 
    word[0].toUpperCase() + word.substring(1)
  ).join(' ');

  return Card(
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['patient_phone'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          typeIcons[request['type']] ?? Icons.person,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          displayType,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Requested: ${DateTime.parse(request['requested_time']).toLocal()}',
            style: const TextStyle(color: Colors.grey),
          ),
          if (request['service_type_name'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Service: ${request['service_type_name']}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!isAssigned && request['type'] != 'assistant')
            ElevatedButton.icon(
              onPressed: () => _findProvider(
                request['id_request'],
                request['type'],
                request['patient_latitude'],
                request['patient_longitude'],
                request,
              ),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Trouver un fournisseur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    ),
  );
}

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Requests'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRequests,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Stats Cards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatsCard(Icons.calendar_today, 'Total', _stats['total'] ?? 0),
                      _buildStatsCard(Icons.medical_services, 'Doctors', _stats['doctor'] ?? 0),
                      _buildStatsCard(Icons.healing, 'Nurses', _stats['nurse'] ?? 0),
                      _buildStatsCard(Icons.volunteer_activism, 'Garde Malades', _stats['garde_malade'] ?? 0),
                      _buildStatsCard(Icons.people, 'Assistants', _stats['assistant'] ?? 0),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilters(),
                const SizedBox(height: 16),
                ..._requests.map(_buildRequestCard),
              ],
            ),
          ),
        ),
      ),
    );
  }
}