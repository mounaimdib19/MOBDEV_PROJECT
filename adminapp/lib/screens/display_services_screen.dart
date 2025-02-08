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
  String _searchQuery = '';
  bool _isLoading = false;
  bool _showActiveServices = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Environment.getservicetypes()}?search=$_searchQuery'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _services = List<Map<String, dynamic>>.from(data['service_types']);
          });
        } else {
          _showError(data['message'] ?? 'Failed to load services');
        }
      } else {
        _showError('Failed to load services. Please try again later.');
      }
    } catch (e) {
      print('Error fetching services: $e');
      _showError('An error occurred. Please check your connection and try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleServiceStatus(Map<String, dynamic> service) async {
    try {
      final response = await http.post(
        Uri.parse(Environment.toggleservicestatus()),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_service_type': service['id_service_type'],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _fetchServices();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service status updated successfully')),
          );
        } else {
          _showError(data['message']);
        }
      } else {
        _showError('Failed to update service status');
      }
    } catch (e) {
      _showError('An error occurred while updating service status');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search services...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _fetchServices();
        },
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _showActiveServices ? Colors.teal : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => setState(() => _showActiveServices = true),
              child: const Text(
                'Active Services',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: !_showActiveServices ? Colors.teal : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => setState(() => _showActiveServices = false),
              child: const Text(
                'Inactive Services',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    final filteredServices = _services.where((service) {
      return service['active'].toString() == (_showActiveServices ? '1' : '0');
    }).toList();
    
    if (filteredServices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _showActiveServices ? 'No active services found' : 'No inactive services found',
          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        final service = filteredServices[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 4,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  service['nom'] ?? 'Unnamed Service',
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _toggleServiceStatus(service),
                  child: Text(
                    _showActiveServices ? 'Désactiver ce service' : 'Activer ce service',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildToggleButtons(),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchServices,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _buildServicesList(),
                ),
              ),
            ),
        ],
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