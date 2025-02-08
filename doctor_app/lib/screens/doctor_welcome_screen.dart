import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'doctor_bottom_nav_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../config/environment.dart';

class DoctorWelcomeScreen extends StatefulWidget {
  final String id_doc;

  const DoctorWelcomeScreen({super.key, required this.id_doc});


  @override
  _DoctorWelcomeScreenState createState() => _DoctorWelcomeScreenState();
}

class _DoctorWelcomeScreenState extends State<DoctorWelcomeScreen> {
  bool _isLoading = true;
  String _doctorName = '';
  bool _isActive = false;
  bool _locationPermissionGranted = false;
  bool _locationServiceEnabled = false;
  bool _isAssistant = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  List<Map<String, dynamic>> _upcomingAppointments = [];
  Timer? _locationUpdateTimer;
  Timer? _statusUpdateTimer;
  Timer? _appointmentsUpdateTimer;
  Timer? _locationServiceCheckTimer;
  List<Map<String, dynamic>> _assistanceRequests = [];
  Timer? _assistanceRequestsUpdateTimer;


@override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch doctor info first as it determines if they're an assistant
      await _fetchDoctorInfo();

      // Check location permissions
      await _checkLocationPermission();

      // Fetch relevant data based on doctor type
      if (_isAssistant) {
        await _fetchAssistanceRequests();
      } else {
        await _fetchUpcomingAppointments();
      }

      // Start all necessary timers
      _startTimers();

    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing app: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  void _stopAllTimers() {
  _locationUpdateTimer?.cancel();
  _statusUpdateTimer?.cancel();
  _appointmentsUpdateTimer?.cancel();
  _locationServiceCheckTimer?.cancel();
  _assistanceRequestsUpdateTimer?.cancel();
  _positionStreamSubscription?.cancel();

  _locationUpdateTimer = null;
  _statusUpdateTimer = null;
  _appointmentsUpdateTimer = null;
  _locationServiceCheckTimer = null;
  _assistanceRequestsUpdateTimer = null;
}

 void _startTimers() {
  // Cancel any existing timers first
  _stopAllTimers();

  // Start status update timer
  _statusUpdateTimer = Timer.periodic(
    const Duration(minutes: 1),
    (_) => _fetchDoctorInfo(),
  );

  // Start location service check
  _locationServiceCheckTimer = Timer.periodic(
    const Duration(seconds: 30),
    (_) async {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled != _locationServiceEnabled) {
        if (!serviceEnabled && _isActive) {
          await _handleLocationServiceDisabled();
        } else {
          await _checkLocationPermission();
        }
      }
    },
  );

  // Start appropriate data fetch timer based on doctor type
  if (_isAssistant) {
    _assistanceRequestsUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),  // Update assistance requests every 30 seconds
      (_) => _fetchAssistanceRequests(),
    );
  } else {
    _appointmentsUpdateTimer = Timer.periodic(
      const Duration(minutes: 1),  // Update appointments every minute
      (_) => _fetchUpcomingAppointments(),
    );
  }

  // Start location updates if active
  if (_isActive && _locationPermissionGranted) {
    // Start continuous location stream
    _startLocationStream();
    
    // Also start backup timer-based location updates
    _locationUpdateTimer = Timer.periodic(
      const Duration(minutes: 1),  // Changed from 2 minutes to 1 minute
      (_) {
        if (_isActive && _locationPermissionGranted) {
          _updateLocation();
        }
      },
    );
  }
}

  



  
  Future<void> _startLocationStream() async {
    // Cancel existing stream if any
    await _positionStreamSubscription?.cancel();
    
    // Start new location stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) async {
      print('New location received: Lat: ${position.latitude}, Lng: ${position.longitude}');
      await _updateLocation(position);
    }, onError: (error) {
      print('Error from location stream: $error');
      _handleLocationError(error);
    });
  }
  void _handleLocationError(dynamic error) {
    if (error is LocationServiceDisabledException) {
      _handleLocationServiceDisabled();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location error: ${error.toString()}')),
      );
    }
  }

  void _startAssistanceRequestsUpdateTimer() {
    _assistanceRequestsUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _fetchAssistanceRequests();
    });
  }
  void _startLocationServiceCheck() {
    _locationServiceCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled != _locationServiceEnabled) {
        if (!serviceEnabled && _isActive) {
          await _handleLocationServiceDisabled();
        } else {
          await _checkLocationPermission();
        }
      }
    });
  }

  void _stopAssistanceRequestsUpdateTimer() {
    _assistanceRequestsUpdateTimer?.cancel();
    _assistanceRequestsUpdateTimer = null;
  }

  Future<void> _handleLocationServiceDisabled() async {
    setState(() {
      _locationServiceEnabled = false;
      _locationPermissionGranted = false;
    });
    if (_isActive) {
      await _deactivateStatus();
    }
    _showLocationServiceDialog();
  }




 Future<void> _fetchAssistanceRequests() async {
  try {
    final response = await http.get(
      Uri.parse(Environment.fetchAssistanceRequests),
    );

    print('Response Status Code: ${response.statusCode}');
    print('Raw Response Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        var data = json.decode(response.body);
        
        print('Parsed Data: $data');
        print('Success: ${data['success']}');
        print('Requests Type: ${data['requests'].runtimeType}');
        print('Requests Length: ${data['requests']?.length}');

        if (data['success'] == true && data['requests'] != null) {
          setState(() {
            _assistanceRequests = List<Map<String, dynamic>>.from(
              data['requests'].map((request) {
                // Explicitly handle potential null values
                return {
                  'id_request': request['id_request'] ?? '',
                  'numero_telephone': request['numero_telephone'] ?? '',
                  'description': request['description'] ?? '',
                  'cree_le': request['cree_le'] ?? ''
                };
              }).toList()
            );
          });
        } else {
          print('No successful requests or empty request list');
        }
      } on FormatException catch (e) {
        print('JSON Parsing Error: $e');
        print('Problematic JSON: ${response.body}');
      }
    } else {
      print('HTTP Error: ${response.statusCode}');
      print('Error Response Body: ${response.body}');
    }
  } catch (e) {
    print('Fetch Assistance Requests Error: $e');
    print('Error Details: ${e.toString()}');
  }
}








 Future<void> _callPatientForAssistance(String patientPhone) async {
  try {
    final cleanPhone = patientPhone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Create the tel URI and launch it
    final telUri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      throw 'Could not launch $telUri';
    }
  } catch (e) {
    print('Error in _callPatientForAssistance: $e');
    _showErrorDialog('An error occurred while trying to make the call: $e');
  }
}





Future<void> _assignAssistanceRequest(int idRequest) async {
  try {
    final response = await http.post(
      Uri.parse(Environment.assignAssistanceRequest),
      body: {
        'id_request': idRequest.toString(),
        'id_doc': widget.id_doc,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request assigned successfully')),
        );
        // Refresh the list after assignment
        await _fetchAssistanceRequests();
      } else {
        _showErrorDialog('Failed to assign request: ${data['message']}');
      }
    } else {
      _showErrorDialog('Server error: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in _assignAssistanceRequest: $e');
    _showErrorDialog('An error occurred while assigning the request: $e');
  }
}


  Future<void> _completeAssistanceRequest(int idRequest) async {
    try {
      final response = await http.post(
        Uri.parse(Environment.completeAssistanceRequest),
        body: {
          'id_request': idRequest.toString(),
          'id_doc': widget.id_doc,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assistance request completed successfully')),
          );
          _fetchAssistanceRequests();
        } else {
          _showErrorDialog('Failed to complete assistance request: ${data['message']}');
        }
      } else {
        _showErrorDialog('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _completeAssistanceRequest: $e');
      _showErrorDialog('An error occurred: $e');
    }
  }

  Future<void> _showLocationServiceDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Services de localisation désactivés'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Les services de localisation sont désactivés. Souhaitez-vous les activer ?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }
   Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showLocationServiceDialog();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les autorisations de localisation sont refusées')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les autorisations de localisation sont définitivement refusées, nous ne pouvons pas demander d\'autorisations.'),
        ),
      );
      return;
    }

    setState(() {
      _locationServiceEnabled = true;
      _locationPermissionGranted = true;
    });

    if (_isActive) {
      _startLocationUpdateTimer();
      await _updateLocation(); // Update location immediately when activated
    }
  }


     Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _handleLocationServiceDisabled();
      return;
    }

    permission = await Geolocator.checkPermission();
    setState(() {
      _locationServiceEnabled = true;
      _locationPermissionGranted = permission == LocationPermission.always || 
                                   permission == LocationPermission.whileInUse;
    });

    if (_locationPermissionGranted && _isActive) {
      _startLocationUpdateTimer();
      await _updateLocation();
    } else {
      _stopLocationUpdateTimer();
      if (_isActive) {
        await _deactivateStatus();
      }
    }
  }

 

 Future<void> _activateStatus() async {
    if (_upcomingAppointments.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'activer le statut pendant que vous avez des rendez-vous à venir'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_locationPermissionGranted) {
      _showLocationPermissionNotification();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(Environment.toggleDoctorStatus),
        body: {
          'id_doc': widget.id_doc,
          'status': 'active',
          'location_permission': 'granted',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _isActive = true;
          });
          
          // Start location updates using regular Geolocator
          _startLocationStream();
        } else {
          print('Failed to activate status: ${data['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
        }
      }
    } catch (e) {
      print('Error activating status: $e');
    }
  }

Future<void> _deactivateStatus() async {
    try {
      // Stop the location stream
      await _positionStreamSubscription?.cancel();

      final response = await http.post(
        Uri.parse(Environment.toggleDoctorStatus),
        body: {
          'id_doc': widget.id_doc,
          'status': 'inactive',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _isActive = false;
          });
        }
      }
    } catch (e) {
      print('Error deactivating status: $e');
    }
  }

  Future<void> _toggleStatus() async {
    if (_isActive) {
      await _deactivateStatus();
    } else {
      await _activateStatus();
    }
  }

  void _showLocationPermissionNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Une autorisation de localisation est requise pour activer votre statut. Veuillez activer les services de localisation et réessayer.'),
        duration: Duration(seconds: 5),
      ),
    );
  }

 

    void _stopLocationUpdateTimer() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  void _startStatusUpdateTimer() {
    _statusUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _fetchDoctorInfo();
    });
  }

  void _stopStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = null;
  }

  void _startAppointmentsUpdateTimer() {
    _appointmentsUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _fetchUpcomingAppointments();
    });
  }

  void _stopAppointmentsUpdateTimer() {
    _appointmentsUpdateTimer?.cancel();
    _appointmentsUpdateTimer = null;
  }

   Future<void> _fetchDoctorInfo() async {
    try {
      final response = await http.get(
        Uri.parse(
            Environment.getDoctorInfo(widget.id_doc)),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _doctorName = '${data['prenom']} ${data['nom']}';
            _isActive = data['status'] == 'active';
            _isAssistant = data['assistant'] == true;
          });
          
          // Debug print
          print('Doctor Info: Name: $_doctorName, Active: $_isActive, Assistant: $_isAssistant');
          
          // Check location permission if status is active
          if (_isActive) {
            await _checkLocationPermission();
          }
        } else {
          print('API returned success: false. Message: ${data['message']}');
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching doctor info: $e');
    }
  }

  Future<void> _fetchUpcomingAppointments() async {
    try {
      final response = await http.get(
        Uri.parse(
           Environment.getUpcomingAppointments(widget.id_doc)),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _upcomingAppointments =
                List<Map<String, dynamic>>.from(data['appointments']);
          });
        } else {
          print('Failed to fetch upcoming appointments: ${data['message']}');
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
        print('API response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching upcoming appointments: $e');
    }
  }

 

    void _startLocationUpdateTimer() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_isActive && _locationPermissionGranted) {
        _updateLocation();
      }
    });
  }

   

  

  Future<void> _deleteAppointment(int idRendezVous) async {
    try {
      final response = await http.post(
        Uri.parse(
           Environment.deleteAppointment),
        body: {'id_rendez_vous': idRendezVous.toString()},
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rendez-vous supprimé avec succès')),
          );
          _fetchUpcomingAppointments();
        } else {
          print('Failed to delete appointment: ${data['message']}');
          _showErrorDialog('Failed to delete appointment: ${data['message']}');
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
        _showErrorDialog(
            'Failed to connect to server. Please try again later.');
      }
    } catch (e) {
      print('Error deleting appointment: $e');
      _showErrorDialog(
          'Une erreur s\'est produite lors de la suppression du rendez-vous. Veuillez réessayer.');
    }
  }

   Future<void> _acceptAppointment(int idRendezVous) async {
    try {
      final response = await http.post(
        Uri.parse(Environment.acceptAppointment),
        body: {
          'id_rendez_vous': idRendezVous.toString(),
          'id_doc': widget.id_doc,
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
          _fetchUpcomingAppointments();
        } else {
          _showErrorDialog('Failed to accept appointment: ${data['message']}');
        }
      } else {
        _showErrorDialog('Failed to connect to server. Please try again later.');
      }
    } catch (e) {
      print('Error accepting appointment: $e');
      _showErrorDialog('An error occurred while accepting the appointment. Please try again.');
    }
  }
Future<void> _updateLocation([Position? position]) async {
    try {
      final Position currentPosition = position ?? await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final response = await http.post(
        Uri.parse(Environment.updateDoctorLocation),
        body: {
          'id_doc': widget.id_doc,
          'latitude': currentPosition.latitude.toString(),
          'longitude': currentPosition.longitude.toString(),
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (!data['success']) {
          print('Failed to update doctor location: ${data['message']}');
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating doctor location: $e');
    }
  }
    Future<void> _completeAppointment(int idRendezVous) async {
  try {
    final response = await http.post(
      Uri.parse(Environment.completeAppointment(idRendezVous)),
      body: {}, // Empty body since we're sending the ID in the URL
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rendez-vous terminé avec succès')),
        );
        _fetchUpcomingAppointments();
      } else {
        _showErrorDialog('Failed to complete appointment: ${data['message']}');
      }
    } else {
      _showErrorDialog('Server error: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in _completeAppointment: $e');
    _showErrorDialog('An error occurred: $e');
  }
}

  Future<double?> _showPriceInputDialog(double suggestedPrice) async {
    double? enteredAmount;
    await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Saisir le montant du paiement'),
          content: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(hintText: 'Suggested price: $suggestedPrice'),
            onChanged: (value) {
              enteredAmount = double.tryParse(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return enteredAmount;
  }
Future<void> _callPatient(String patientPhone) async {
  try {
    await launchUrl(Uri.parse('tel:$patientPhone'));
  } catch (e) {
    print('Error calling patient: $e');
    _showErrorDialog('Une erreur s\'est produite lors de l\'appel du patient. Veuillez réessayer.');
  }
}
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

    @override
  Widget build(BuildContext context) {
    // Debug print in build method
    print('Building UI: isAssistant: $_isAssistant');

    return Scaffold(
      
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchDoctorInfo();
          if (_isAssistant) {
            await _fetchAssistanceRequests();
          } else {
            await _fetchUpcomingAppointments();
          }
          await _checkLocationPermission();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                // Debug text to show current status
                // Conditional rendering with fallback
                if (_isAssistant)
                  _buildAssistanceRequestsSection()
                else if (!_isAssistant)
                  _buildUpcomingAppointmentsSection()
                else
                  const Text('Error: Unable to determine doctor type', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: DoctorBottomNavBar(
        currentIndex: 0,
        id_doc: widget.id_doc,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _fetchDoctorInfo();
          if (_isAssistant) {
            await _fetchAssistanceRequests();
          } else {
            await _fetchUpcomingAppointments();
          }
          await _checkLocationPermission();
          if (_isActive && _locationPermissionGranted) {
            await _updateLocation();
          }
          // Force a rebuild of the UI
          setState(() {});
        },
        backgroundColor: const Color.fromARGB(255, 52, 198, 91),
        child: const Icon(Icons.refresh),
      ),
    );
  }
 Widget _buildAssistanceRequestsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Demandes d\'assistance telephoniques',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
      ),
      const SizedBox(height: 10),
      if (_assistanceRequests.isNotEmpty)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _assistanceRequests.length,
          itemBuilder: (context, index) {
            final request = _assistanceRequests[index];
            return _buildAssistanceRequestCard(request);
          },
        )
      else
        _buildNoAssistanceRequestsCard(),
    ],
  );
}
Widget _buildAssistanceRequestCard(Map<String, dynamic> request) {
    // Parse the creation date
    final requestDateTime = DateTime.parse(request['cree_le']);
    final formattedDate = DateFormat('MMM d, yyyy').format(requestDateTime);
    final formattedTime = DateFormat('HH:mm').format(requestDateTime);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Demande d\'assistance', // Since patient name is not in the data
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Urgent',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Numero: ${request['numero_telephone']}',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Description: ${request['description']}',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              '$formattedDate at $formattedTime',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.phone,
                  color: Colors.green,
                  onPressed: () => _callPatientForAssistance(
                    request['numero_telephone'].toString(),
                  ),
                  label: 'Appeler Patient',
                ),
                /*_buildActionButton(
                  icon: Icons.assignment_turned_in,
                  color: Colors.orange,
                  onPressed: () => _assignAssistanceRequest(int.parse(request['id_request'])),
                  label: 'Assign',
                ),*/
                _buildActionButton(
                  icon: Icons.check_circle,
                  color: Colors.blue,
                  onPressed: () => _completeAssistanceRequest(int.parse(request['id_request'])),
                  label: 'Completer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  
Widget _buildNoAssistanceRequestsCard() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        'Aucune demande d\'assistance urgente',
        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
      ),
    ),
  );
}

 Widget _buildWelcomeCard() {
  return SizedBox(
    width: double.infinity,
    child: Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _locationPermissionGranted
                ? [const Color.fromARGB(255, 92, 192, 112), const Color.fromARGB(255, 48, 159, 61)]
                : [const Color.fromARGB(255, 142, 220, 91), const Color.fromARGB(255, 83, 198, 106)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue, Dr. $_doctorName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildLocationPermissionButton(),
              const SizedBox(height: 15),
              if (_locationPermissionGranted) _buildStatusToggle(),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildLocationPermissionButton() {
    return ElevatedButton.icon(
      onPressed: _requestLocationPermission,
      icon: Icon(_locationPermissionGranted ? Icons.check_circle : Icons.location_on),
      label: Text(
        _locationPermissionGranted 
          ? 'Location Permission Granted' 
          : 'Grant Location Permission',
        style: const TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.indigo,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Status: ${_isActive ? 'Active' : 'Inactive'}',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Switch(
            value: _isActive,
            onChanged: (value) {
              _toggleStatus();
            },
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
          ),
        ],
      ),
    );
  }

 Widget _buildUpcomingAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rendez-vous à venir',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        const SizedBox(height: 10),
        if (_upcomingAppointments.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _upcomingAppointments.length,
            itemBuilder: (context, index) {
              final appointment = _upcomingAppointments[index];
              return _buildAppointmentCard(appointment);
            },
          )
        else
          _buildNoAppointmentsCard(),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    // Log the entire appointment data
    print('Appointment data: $appointment');

    final appointmentDateTime = DateTime.parse(appointment['appointment_datetime']);
    final formattedDate = DateFormat('MMM d, yyyy').format(appointmentDateTime);
    final formattedTime = DateFormat('HH:mm').format(appointmentDateTime);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${appointment['patient_name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment['statut']),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  appointment['statut'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Service: ${appointment['service_name']}',
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            '$formattedDate at $formattedTime',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
           Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (appointment['statut'] == 'en_attente')
                  _buildActionButton(
                    icon: Icons.cancel,
                    color: Colors.red,
                    onPressed: () => _deleteAppointment(appointment['id_rendez_vous']),
                    label: 'Cancel',
                  ),
                if (appointment['statut'] == 'en_attente')
                  _buildActionButton(
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onPressed: () => _acceptAppointment(appointment['id_rendez_vous']),
                    label: 'Accept',
                  ),
                if (appointment['statut'] == 'accepte')
                  _buildActionButton(
                    icon: Icons.done_all,
                    color: Colors.blue,
                    onPressed: () {
                      // Log the specific fields we're interested in
                      print('id_rendez_vous: ${appointment['id_rendez_vous']}');
                      print('id_doctor_service: ${appointment['id_doctor_service']}');
                      
                      final int? idDoctorService = appointment['id_doctor_service'] as int?;
                       {
                        _completeAppointment(appointment['id_rendez_vous']);
                      }
                    },
                    label: 'Complete',
                  ),
                _buildActionButton(
                  icon: Icons.phone,
                  color: Colors.indigo,
                  onPressed: () => _callPatient(appointment['patient_phone'].toString()),
                  label: 'Call',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


 Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String label,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }


    Widget _buildNoAppointmentsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Aucun rendez-vous à venir',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return Colors.orange;
      case 'accepte':
        return Colors.green;
      case 'complete':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}