// view_administrators_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

class ViewAdministratorsScreen extends StatefulWidget {
  const ViewAdministratorsScreen({super.key});

  @override
  _ViewAdministratorsScreenState createState() => _ViewAdministratorsScreenState();
}

class _ViewAdministratorsScreenState extends State<ViewAdministratorsScreen> {
  List<Map<String, dynamic>> administrators = [];

  @override
  void initState() {
    super.initState();
    fetchAdministrators();
  }

  Future<void> fetchAdministrators() async {
  try {
    final response = await http.get(Uri.parse(Environment.getalladministrators()));
    
    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      if (decodedResponse is List) {
        setState(() {
          administrators = List<Map<String, dynamic>>.from(decodedResponse);
        });
      } else {
        print('Unexpected response format: ${response.body}');
      }
    } else {
      print('Failed to load administrators. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching administrators: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Administrators'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        itemCount: administrators.length,
        itemBuilder: (context, index) {
          final admin = administrators[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
             leading: CircleAvatar(
  backgroundImage: admin['photo_profil'] != null
      ? NetworkImage(Environment.getProfileImageUrl(admin['photo_profil']))
      : null,
  child: admin['photo_profil'] == null ? const Icon(Icons.person) : null,
),
              title: Text('${admin['prenom']} ${admin['nom']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${admin['adresse_email']}'),
                  Text('Type: ${admin['type']}'),
                  Text('Status: ${admin['statut']}'),
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