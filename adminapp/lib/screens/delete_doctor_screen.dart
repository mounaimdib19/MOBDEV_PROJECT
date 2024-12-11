import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';


class DeleteDoctorScreen extends StatefulWidget {
  const DeleteDoctorScreen({super.key});

  @override
  _DeleteDoctorScreenState createState() => _DeleteDoctorScreenState();
}

class _DeleteDoctorScreenState extends State<DeleteDoctorScreen> {
  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    final response = await http.get(Uri.parse(Environment.getdoctors('doctor')));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _doctors = List<Map<String, dynamic>>.from(data['doctors']);
      });
    }
  }

  Future<void> _deleteDoctor(int id) async {
    final response = await http.post(
      Uri.parse(Environment.deletedoctor()),
      body: json.encode({'id_doc': id}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doctor deleted successfully')));
        _fetchDoctors();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete doctor')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Doctor')),
      body: ListView.builder(
        itemCount: _doctors.length,
        itemBuilder: (context, index) {
          final doctor = _doctors[index];
          return ListTile(
            title: Text('${doctor['nom']} ${doctor['prenom']}'),
            subtitle: Text(doctor['adresse_email']),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteDoctor(doctor['id_doc']),
            ),
          );
        },
      ),
    );
  }
}