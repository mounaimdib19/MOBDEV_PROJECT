import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';


class ViewPatientsScreen extends StatefulWidget {
  const ViewPatientsScreen({super.key});

  @override
  _ViewPatientsScreenState createState() => _ViewPatientsScreenState();
}

class _ViewPatientsScreenState extends State<ViewPatientsScreen> {
  List<Map<String, dynamic>> patients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    try {
      final response = await http.get(
        Uri.parse(Environment.getpatients()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          patients = List<Map<String, dynamic>>.from(data['patients']);
          isLoading = false;
        });
      } else {
        print('Failed to fetch patients');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching patients: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Patients'),
        backgroundColor: Colors.indigo,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text('${patient['nom']} ${patient['prenom']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phone: ${patient['numero_telephone']}'),
                        Text('Email: ${patient['adresse_email']}'),
                        Text('Appointments: ${patient['appointment_count']}'),
                        Text('Total Payment: \$${patient['total_payment']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}