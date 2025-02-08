// delete_service_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';


class DeleteServiceScreen extends StatefulWidget {
  const DeleteServiceScreen({super.key});

  @override
  _DeleteServiceScreenState createState() => _DeleteServiceScreenState();
}

class _DeleteServiceScreenState extends State<DeleteServiceScreen> {
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
  final response = await http.get(Uri.parse(Environment.getservicetypes()));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['success']) {
      setState(() {
        _services = List<Map<String, dynamic>>.from(data['service_types'])
            .map((service) {
              // Ensure id_service_type is an integer
              service['id_service_type'] = int.parse(service['id_service_type']);
              return service;
            }).toList();
      });
    }
  }
}

 Future<void> _deleteService(int id) async {
  try {
    final response = await http.post(
      Uri.parse(Environment.deleteservice()),
      body: json.encode({'id_service_type': id}),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Optional: Add any additional headers if needed
      },
    );

    // Add more detailed error handling
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service deleted successfully'))
        );
        _fetchServices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to delete service'))
        );
      }
    } else {
      // Handle different HTTP status codes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.statusCode}'))
      );
    }
  } catch (e) {
    // Catch and display any network or parsing errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e'))
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supprimer Service')),
      body: ListView.builder(
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return ListTile(
            title: Text(service['nom']),
            subtitle: Text(service['has_fixed_price'] == 1 ? 'Fixed Price: ${service['fixed_price']}' : 'Variable Price'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteService(service['id_service_type']),
            ),
          );
        },
      ),
    );
  }
}