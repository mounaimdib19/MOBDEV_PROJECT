import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';


class DeletePatientScreen extends StatefulWidget {
  const DeletePatientScreen({super.key});

  @override
  _DeletePatientScreenState createState() => _DeletePatientScreenState();
}

class _DeletePatientScreenState extends State<DeletePatientScreen> {
  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    final response = await http.get(Uri.parse(Environment.getpatients()));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _patients = List<Map<String, dynamic>>.from(data['patients']);
        });
      }
    }
  }

  Future<void> _deletePatient(int id) async {
    final response = await http.post(
      Uri.parse(Environment.deletepatient()),
      body: json.encode({'id_patient': id}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient deleted successfully')));
        _fetchPatients();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete patient')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Patient')),
      body: ListView.builder(
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          final patient = _patients[index];
          return ListTile(
            title: Text('${patient['nom']} ${patient['prenom']}'),
            subtitle: Text(patient['adresse_email']),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deletePatient(patient['id_patient']),
            ),
          );
        },
      ),
    );
  }
}