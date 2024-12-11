import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_service_screen.dart';
import 'edit_service_screen.dart';
import '../config/environment.dart';


class DisplayServicesScreen extends StatefulWidget {
  const DisplayServicesScreen({super.key});

  @override
  _DisplayServicesScreenState createState() => _DisplayServicesScreenState();
}

class _DisplayServicesScreenState extends State<DisplayServicesScreen> {
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final response = await http.get(
        Uri.parse(Environment.getservicetypes()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _services = List<Map<String, dynamic>>.from(data['service_types']);
          });
        } else {
          print('API returned an error: ${data['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to load services')),
          );
        }
      } else {
        print('Failed to fetch services. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load services. Please try again later.')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please check your connection and try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return Card(
            margin: const EdgeInsets.all(8),
            elevation: 4,
            child: ListTile(
              title: Text(
                service['nom'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Fixed Price: ${service['has_fixed_price'] == '1' ? 'Yes' : 'No'}\n'
                'Price: ${service['fixed_price'] ?? 'N/A'}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditServiceScreen(service: service),
                    ),
                  ).then((_) => _fetchServices());
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddServicesScreen()),
          ).then((_) => _fetchServices());
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}