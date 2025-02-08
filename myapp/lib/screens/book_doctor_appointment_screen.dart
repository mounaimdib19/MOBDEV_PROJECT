import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';
import '../config/environment.dart';

class BookDoctorAppointmentScreen extends StatefulWidget {
  final int id_patient;

  const BookDoctorAppointmentScreen({super.key, required this.id_patient});

  @override
  _BookDoctorAppointmentScreenState createState() => _BookDoctorAppointmentScreenState();
}

class _BookDoctorAppointmentScreenState extends State<BookDoctorAppointmentScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _locationPermissionGranted = false;
  bool _locationServiceEnabled = false;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;

 @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupLocationMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceStatusStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationPermission();
    }
  }
Future<void> _setupLocationMonitoring() async {
    // Initial check
    await _checkLocationPermission();

    // Listen to service status changes
    _serviceStatusStreamSubscription = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) {
        setState(() {
          _locationServiceEnabled = status == ServiceStatus.enabled;
        });
        if (_locationServiceEnabled) {
          _checkLocationPermission();
        }
      }
    );
  }

Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationServiceEnabled = false;
        _locationPermissionGranted = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    setState(() {
      _locationServiceEnabled = true;
      _locationPermissionGranted = permission == LocationPermission.always || 
                                 permission == LocationPermission.whileInUse;
    });
  }

 Future<void> _showLocationServiceDialog() async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Wrap(  // Changed from Row to Wrap to handle overflow
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.location_off, color: Colors.red[400]),
            const Text('Services de localisation désactivés'),
          ],
        ),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Les services de localisation sont désactivés. Souhaitez-vous les activer ?'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('No', style: TextStyle(color: Colors.grey[600])),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,  // Changed to clear blue
              foregroundColor: Colors.white, // Added white text
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Activer la localisation'),
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


  void _showNotificationDialog(String title, String message, IconData icon, Color iconColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
        _showNotificationDialog(
          'Permission refusée',
          'Des autorisations de localisation sont nécessaires pour demander un rendez-vous chez un médecin.',
          Icons.location_off,
          Colors.red[400]!
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showNotificationDialog(
        'Permission refusée',
        'Les autorisations de localisation sont définitivement refusées. Veuillez les activer dans les paramètres de votre appareil.',
        Icons.location_off,
        Colors.red[400]!
      );
      return;
    }

    setState(() {
      _locationServiceEnabled = true;
      _locationPermissionGranted = true;
    });
  }

 Future<void> _createDoctorRequest() async {
  if (!_locationPermissionGranted || !_locationServiceEnabled) {
    await _requestLocationPermission();
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw TimeoutException('Location retrieval timed out');
      }
    );

    final response = await http.post(
      Uri.parse(Environment.createDoctorRequest),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'id_patient': widget.id_patient.toString(),
        'patient_latitude': position.latitude.toString(),
        'patient_longitude': position.longitude.toString(),
        'requested_time': DateTime.now().toIso8601String(),
      },
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw TimeoutException('Server request timed out');
      }
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      
      if (data['success'] == true) {
        // Notify admins after successful request
        try {
          await http.get(
            Uri.parse(Environment.adminNotifications),
          ).timeout(
            const Duration(seconds: 10),
          );
        } catch (e) {
          // Don't show error to user if admin notification fails
          debugPrint('Admin notification failed: $e');
        }

        _showNotificationDialog(
          'Success!',
          'Demande de médecin soumise avec succès !\nNous allons bientôt attribuer un médecin.',
          Icons.check_circle,
          Colors.green[400]!
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });
      } else {
        _showNotificationDialog(
          'Request Failed',
          data['message'] ?? 'Échec de la soumission de la demande du médecin.',
          Icons.error,
          Colors.red[400]!
        );
      }
    } else {
      _showNotificationDialog(
        'Connection Error',
        'Impossible de se connecter au serveur. Veuillez réessayer.',
        Icons.wifi_off,
        Colors.orange[400]!
      );
    }
  } on TimeoutException {
    _showNotificationDialog(
      'Timeout Error',
      'La demande a expiré. Veuillez vérifier votre connexion Internet.',
      Icons.timer_off,
      Colors.orange[400]!
    );
  } on SocketException {
    _showNotificationDialog(
      'Network Error',
      'Erreur réseau. Veuillez vérifier votre connexion Internet.',
      Icons.wifi_off,
      Colors.orange[400]!
    );
  } catch (e) {
    _showNotificationDialog(
      'Error',
      'Une erreur inattendue s\'est produite. Veuillez réessayer.',
      Icons.error,
      Colors.red[400]!
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demander un médecin'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[100]!,
              Colors.blue[50]!,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Status Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Status',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.blue,  // Changed to blue
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              _locationServiceEnabled ? Icons.location_on : Icons.location_off,
                              color: _locationServiceEnabled ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Services de localisation: ${_locationServiceEnabled ? "activés" : "desactivés"}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _locationPermissionGranted ? Icons.check_circle : Icons.error,
                              color: _locationPermissionGranted ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Permissions de localisation: ${_locationPermissionGranted ? "Guaranties" : "non-guaranties"}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Information Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.medical_services,
                          size: 48,
                          color: Colors.blue,  // Changed to blue
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Demander une visite d\'un  médecin',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,  // Changed to blue
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Notre médecin se déplacera chez vous pour une visite à domicile.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createDoctorRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,  // Changed to blue
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Demander un médecin',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }}