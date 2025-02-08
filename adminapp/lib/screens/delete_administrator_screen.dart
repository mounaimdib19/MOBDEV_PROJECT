// delete_administrator_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';


class DeleteAdministratorScreen extends StatefulWidget {
  const DeleteAdministratorScreen({super.key});

  @override
  _DeleteAdministratorScreenState createState() => _DeleteAdministratorScreenState();
}

class _DeleteAdministratorScreenState extends State<DeleteAdministratorScreen> {
  List<Map<String, dynamic>> _administrators = [];

  @override
  void initState() {
    super.initState();
    _fetchAdministrators();
  }

  Future<void> _fetchAdministrators() async {
    final response = await http.get(Uri.parse(Environment.getalladministrators()));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _administrators = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> _deleteAdministrator(int id) async {
    final response = await http.post(
      Uri.parse(Environment.deleteadministrator()),
      body: json.encode({'id_admin': id}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrator deleted successfully')));
        _fetchAdministrators();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete administrator')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supprimer Administrateur')),
      body: ListView.builder(
        itemCount: _administrators.length,
        itemBuilder: (context, index) {
          final admin = _administrators[index];
          return ListTile(
            title: Text('${admin['prenom']} ${admin['nom']}'),
            subtitle: Text(admin['adresse_email']),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteAdministrator(admin['id_admin']),
            ),
          );
        },
      ),
    );
  }
}