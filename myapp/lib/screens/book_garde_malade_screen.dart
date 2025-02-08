import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';
import '../config/environment.dart';

class BookGardeMaladeScreen extends StatefulWidget {
  final int id_patient;

  const BookGardeMaladeScreen({super.key, required this.id_patient});

  @override
  _BookGardeMaladeScreenState createState() => _BookGardeMaladeScreenState();
}

class _BookGardeMaladeScreenState extends State<BookGardeMaladeScreen> {
  bool _isLoading = false;
  bool _locationPermissionGranted = false;
  bool _locationServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
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
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.blue[50],
          title: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.location_off, color: Colors.red[400], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Services de localisation désactivés',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text(
              'Les services de localisation sont désactivés. Souhaitez-vous les activer ?',
              style: TextStyle(fontSize: 16),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Non', 
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Activer la localisation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openLocationSettings();
                },
              ),
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
          'Des autorisations de localisation sont nécessaires pour demander un garde malade.',
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

  Future<void> _createGardeMaladeRequest() async {
  if (!_locationPermissionGranted || !_locationServiceEnabled) {
    await _requestLocationPermission();
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Location retrieval timed out');
      }
    );

    // First, create the garde malade request
    final response = await http.post(
      Uri.parse(Environment.createGardeMaladeRequest),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'id_patient': widget.id_patient.toString(),
        'description': '',
        'patient_latitude': position.latitude.toString(),
        'patient_longitude': position.longitude.toString(),
        'requested_time': DateTime.now().toIso8601String(),
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Server request timed out');
      }
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      
      if (data['success'] == true) {
        // If the request was successful, notify admins
        try {
          await http.get(
            Uri.parse(Environment.adminNotifications),
          ).timeout(
            const Duration(seconds: 10),
          );
        } catch (e) {
          // Even if admin notification fails, we don't want to show an error to the user
          // as their request was still successful
          debugPrint('Admin notification failed: $e');
        }

        _showNotificationDialog(
          'Success!',
          'Demande de garde malade soumise avec succès !\nNous allons bientôt attribuer un soignant.',
          Icons.check_circle,
          Colors.green[400]!
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });
      } else {
        _showNotificationDialog(
          'Request Failed',
          data['message'] ?? 'Failed to submit garde malade request.',
          Icons.error,
          Colors.red[400]!
        );
      }
    } else {
      _showNotificationDialog(
        'Connection Error',
        'Failed to connect to server. Please try again.',
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
      'An unexpected error occurred. Please try again.',
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
        title: const Text('Demander un Garde Malade'),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                // Status Card with updated design
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.blue[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statut de localisation',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _locationServiceEnabled ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _locationServiceEnabled ? Icons.location_on : Icons.location_off,
                                color: _locationServiceEnabled ? Colors.green[600] : Colors.red[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Services de localisation: ${_locationServiceEnabled ? "Enabled" : "Disabled"}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _locationServiceEnabled ? Colors.green[800] : Colors.red[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _locationPermissionGranted ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _locationPermissionGranted ? Icons.check_circle : Icons.error,
                                color: _locationPermissionGranted ? Colors.green[600] : Colors.red[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Location Permission: ${_locationPermissionGranted ? "Granted" : "Not Granted"}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _locationPermissionGranted ? Colors.green[800] : Colors.red[800],
                                ),
                              ),
                            ],
                          ),
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
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.blue[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Demander une visite de Garde Malade',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Notre soignant se rendra à votre emplacement pour vous aider.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createGardeMaladeRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
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
                                    'Demander un Garde Malade',
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
  }
}