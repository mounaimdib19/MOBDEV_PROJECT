import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

class SpecialtyManagementScreen extends StatefulWidget {
  const SpecialtyManagementScreen({super.key});

  @override
  _SpecialtyManagementScreenState createState() => _SpecialtyManagementScreenState();
}

class _SpecialtyManagementScreenState extends State<SpecialtyManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // For specialties
  final TextEditingController _specialtyNameController = TextEditingController();
  List<Map<String, dynamic>> _specialties = [];
  
  // For sub-specialties
  final TextEditingController _subSpecialtyNameController = TextEditingController();
  int? _selectedSpecialtyId;
  List<Map<String, dynamic>> _subSpecialties = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSpecialties();
    _fetchSubSpecialties();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _specialtyNameController.dispose();
    _subSpecialtyNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchSpecialties() async {
    try {
      final response = await http.get(Uri.parse(Environment.getspecialties2()));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _specialties = List<Map<String, dynamic>>.from(data['specialties']);
          });
        }
      }
    } catch (e) {
      _showError('Error fetching specialties: $e');
    }
  }

  Future<void> _fetchSubSpecialties() async {
    try {
      final response = await http.get(
        Uri.parse(Environment.getsubspecialties(_selectedSpecialtyId)),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _subSpecialties = List<Map<String, dynamic>>.from(data['subspecialties']);
          });
        }
      }
    } catch (e) {
      _showError('Error fetching subspecialties: $e');
    }
  }

  Future<void> _addSpecialty() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await http.post(
        Uri.parse(Environment.addspecialty()),
        body: {
          'nom_specialite': _specialtyNameController.text,
        },
      );

      final data = json.decode(response.body);
      if (data['success']) {
        _specialtyNameController.clear();
        await _fetchSpecialties();
        _showSuccess('Specialty added successfully');
      } else {
        _showError(data['message']);
      }
    } catch (e) {
      _showError('Error adding specialty: $e');
    }
  }

  Future<void> _addSubSpecialty() async {
    if (!_formKey.currentState!.validate() || _selectedSpecialtyId == null) {
      _showError('Please select a specialty and enter a subspecialty name');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(Environment.addsubspecialty()),
        body: {
          'nom_sous_specialite': _subSpecialtyNameController.text,
          'specialite_parent': _selectedSpecialtyId.toString(),
        },
      );

      final data = json.decode(response.body);
      if (data['success']) {
        _subSpecialtyNameController.clear();
        await _fetchSubSpecialties();
        _showSuccess('Subspecialty added successfully');
      } else {
        _showError(data['message']);
      }
    } catch (e) {
      _showError('Error adding subspecialty: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'Gestion des spécialités',
        style: TextStyle(color: Colors.white),
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white, // Sets the active tab text color
        unselectedLabelColor: Colors.white70, // Sets the inactive tab text color
        tabs: const [
          Tab(text: 'Spécialités'),
          Tab(text: 'Sous-spécialités'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabController,
      children: [
        _buildSpecialtiesTab(),
        _buildSubSpecialtiesTab(),
      ],
    ),
  );
}

  Widget _buildSpecialtiesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _specialtyNameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la spécialité',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Ce champ est requis' : null,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _addSpecialty,
            child: const Text('Ajouter une spécialité'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _specialties.length,
              itemBuilder: (context, index) {
                final specialty = _specialties[index];
                return ListTile(
                  title: Text(specialty['nom_specialite']),
                  leading: const Icon(Icons.medical_services),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSpecialtiesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            value: _selectedSpecialtyId,
            decoration: const InputDecoration(
              labelText: 'Spécialité parent',
              border: OutlineInputBorder(),
            ),
            items: _specialties.map<DropdownMenuItem<int>>((specialty) {
              return DropdownMenuItem<int>(
                value: int.parse(specialty['id_specialite'].toString()),
                child: Text(specialty['nom_specialite'].toString()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSpecialtyId = value;
              });
              _fetchSubSpecialties();
            },
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _subSpecialtyNameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la sous-spécialité',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Ce champ est requis' : null,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _addSubSpecialty,
            child: const Text('Ajouter une sous-spécialité'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _subSpecialties.length,
              itemBuilder: (context, index) {
                final subSpecialty = _subSpecialties[index];
                return ListTile(
                  title: Text(subSpecialty['nom_sous_specialite']),
                  subtitle: Text(subSpecialty['parent_specialite_nom']),
                  leading: const Icon(Icons.subdirectory_arrow_right),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}