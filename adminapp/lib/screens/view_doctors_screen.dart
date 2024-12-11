import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

class ViewDoctorsScreen extends StatefulWidget {
  final String type;

  const ViewDoctorsScreen({super.key, required this.type});

  @override
  _ViewDoctorsScreenState createState() => _ViewDoctorsScreenState();
}

class _ViewDoctorsScreenState extends State<ViewDoctorsScreen> {
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(Environment.getdoctors(widget.type)),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _doctors = List<Map<String, dynamic>>.from(data['doctors']);
            _isLoading = false;
          });
        } else {
          print('API returned success: false. Message: ${data['message']}');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching doctors: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View ${widget.type.capitalize()}s'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                var doctor = _doctors[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('${doctor['nom']} ${doctor['prenom']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${doctor['adresse_email']}'),
                        Text('Address: ${doctor['adresse']}, ${doctor['commune']}, ${doctor['wilaya']}'),
                        Text('Appointments: ${doctor['appointments_count']}'),
                        Text('Total Earnings: ${doctor['total_earnings']} DZD'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}