import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/environment.dart';

class LocationService {
  static const String updateLocationTask = "updateLocationTask";

  // Initialize location service
  static Future<void> initialize() async {
    try {
      // Initialize Workmanager
      await Workmanager().initialize(callbackDispatcher);
      
      // Request location permissions
      await _requestPermissions();
    } catch (e) {
      print('Error initializing LocationService: $e');
      rethrow;
    }
  }

  // Request necessary location permissions
  static Future<void> _requestPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw Exception('Location services are disabled');
      }
    } catch (e) {
      print('Error requesting location permissions: $e');
      rethrow;
    }
  }

  // Start tracking doctor's location
  static Future<void> startLocationTracking(String doctorId) async {
    try {
      // Store doctor ID in shared preferences for background access
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString('doctor_id', doctorId);
      });

      // Register periodic task
      await Workmanager().registerPeriodicTask(
        updateLocationTask,
        updateLocationTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        inputData: {'doctorId': doctorId},
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      
      // Perform initial location update
      await _updateLocation(doctorId);
    } catch (e) {
      print('Error starting location tracking: $e');
      rethrow;
    }
  }

  // Stop tracking doctor's location
  static Future<void> stopLocationTracking() async {
    try {
      await Workmanager().cancelByUniqueName(updateLocationTask);
      await SharedPreferences.getInstance().then((prefs) {
        prefs.remove('doctor_id');
      });
    } catch (e) {
      print('Error stopping location tracking: $e');
      rethrow;
    }
  }

  // Update location immediately
  static Future<bool> _updateLocation(String doctorId) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final response = await http.post(
        Uri.parse(Environment.updateDoctorLocation),
        body: {
          'id_doc': doctorId,
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] ?? false;
      }
      
      return false;
    } catch (e) {
      print('Error updating location: $e');
      return false;
    }
  }

  // Check if tracking is active
  static Future<bool> isTrackingActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('doctor_id');
    } catch (e) {
      print('Error checking tracking status: $e');
      return false;
    }
  }

  // Get stored doctor ID
  static Future<String?> getTrackedDoctorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('doctor_id');
    } catch (e) {
      print('Error getting tracked doctor ID: $e');
      return null;
    }
  }
}

// This needs to be at the top level of the file
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == LocationService.updateLocationTask) {
        // Get doctorId from inputData or SharedPreferences as backup
        String? doctorId = inputData?['doctorId'];
        if (doctorId == null) {
          final prefs = await SharedPreferences.getInstance();
          doctorId = prefs.getString('doctor_id');
        }
        
        if (doctorId != null) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          final response = await http.post(
            Uri.parse(Environment.updateDoctorLocation),
            body: {
              'id_doc': doctorId,
              'latitude': position.latitude.toString(),
              'longitude': position.longitude.toString(),
            },
          );

          return response.statusCode == 200;
        }
      }
      return false;
    } catch (e) {
      print('Background task error: $e');
      return false;
    }
  });
}