import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../config/environment.dart';

class BookNurseAppointmentScreen extends StatefulWidget {
  final int id_patient;
  final int? id_service_type;

  const BookNurseAppointmentScreen({
    super.key, 
    required this.id_patient, 
    this.id_service_type
  });

  @override
  _BookNurseAppointmentScreenState createState() => _BookNurseAppointmentScreenState();
}

class _BookNurseAppointmentScreenState extends State<BookNurseAppointmentScreen> {
  List<dynamic> _services = [];
  List<dynamic> _filteredServices = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  int? _preSelectedServiceTypeId;

  @override
  void initState() {
    super.initState();
    _preSelectedServiceTypeId = widget.id_service_type;
    _fetchNurseServices();
    _searchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled. Please enable them.'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are denied.'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied. Please enable them in settings.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    // Get current position
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _fetchNurseServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(Environment.getNurseServices),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          setState(() {
            _services = result['services'];
            _filteredServices = _services;
            _isLoading = false;

            if (_preSelectedServiceTypeId != null) {
              final preSelectedService = _services.firstWhere(
                (service) => int.parse(service['id_service_type']) == _preSelectedServiceTypeId,
                orElse: () => null,
              );
              
              if (preSelectedService != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _confirmServiceSelection(preSelectedService);
                });
              }
            }
          });
        } else {
          throw Exception('Failed to fetch services: ${result['message']}');
        }
      } else {
        throw Exception('Error connecting to the server');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching nurse services: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  void _filterServices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredServices = _services.where((service) => 
        service['nom'].toString().toLowerCase().contains(query)
      ).toList();
    });
  }

  Future<void> _createNurseAssistanceRequest(int serviceTypeId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(Environment.bookNurseAppointment),
        body: {
          'id_patient': widget.id_patient.toString(),
          'id_service_type': serviceTypeId.toString(),
          'patient_latitude': position.latitude.toString(),
          'patient_longitude': position.longitude.toString(),
          'requested_time': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nurse assistance request submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Failed to submit request: ${result['message']}');
        }
      } else {
        throw Exception('Error connecting to the server');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error creating nurse assistance request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmServiceSelection(dynamic service) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Service'),
          content: Text('Do you want to request ${service['nom']} service?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Confirm', style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
                _createNurseAssistanceRequest(int.parse(service['id_service_type']));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Nurse Assistance'),
        backgroundColor: const Color(0xFF1B5A90),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'rechercher un service',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _filteredServices.isEmpty
                  ? const Center(
                      child: Text(
                        'Pas de services trouvés', 
                        style: TextStyle(fontSize: 18, color: Colors.grey)
                      )
                    )
                  : ListView.builder(
                      itemCount: _filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = _filteredServices[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: ListTile(
                            leading: service['picture_url'] != null
                              ? Image.network(
                                  Environment.getServiceImageUrl(int.parse(service['id_service_type'])),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.medical_services);
                                  },
                                )
                              : const Icon(Icons.medical_services),
                            title: Text(service['nom']),
                            subtitle: Text(
                              service['has_fixed_price'] == '1'
                                ? 'Fixed Price: ${service['fixed_price']} DA'
                                : 'Price varies',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _confirmServiceSelection(service),
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