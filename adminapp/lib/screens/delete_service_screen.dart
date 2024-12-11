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
          _services = List<Map<String, dynamic>>.from(data['service_types']);
        });
      }
    }
  }

  Future<void> _deleteService(int id) async {
    final response = await http.post(
      Uri.parse(Environment.deleteservice()),
      body: json.encode({'id_service_type': id}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service deleted successfully')));
        _fetchServices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete service')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Service')),
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