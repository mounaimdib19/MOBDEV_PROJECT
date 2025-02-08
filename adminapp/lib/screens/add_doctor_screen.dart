import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';


class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  _AddDoctorScreenState createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _nom = '';
  String _prenom = '';
  String _adresse = '';
  String? _wilaya;
  String? _commune;
  String _email = '';
  String _motDePasse = '';
  String _numeroTelephone = '';
  bool _consultationDomicile = false;
  bool _consultationCabinet = false;
  bool _estInfirmier = false;
  bool _estGM = false;
  bool _assistantTelephonique = false;
  String _status = 'inactive';
  String? _specialite;
  String? _sousSpecialite;

  List<Map<String, dynamic>> _wilayas = [];
  List<Map<String, dynamic>> _communes = [];
  List<Map<String, dynamic>> _specialites = [];
  List<Map<String, dynamic>> _sousSpecialites = [];
  
  List<Map<String, dynamic>> _serviceTypes = [];
  final List<Map<String, dynamic>> _selectedServices = [];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredServiceTypes = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchWilayas();
    _fetchSpecialites();
    _fetchServiceTypes();
    _searchController.addListener(_filterServices);

  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWilayas() async {
    final response = await http.get(Uri.parse(Environment.getwilayas()));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _wilayas = List<Map<String, dynamic>>.from(data['wilayas']);
        });
      }
    }
  }

  Future<void> _fetchCommunes(String wilaya) async {
    final response = await http.get(Uri.parse('${Environment.getcommunes()}?wilaya=$wilaya'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _communes = List<Map<String, dynamic>>.from(data['communes']);
        });
      }
    }
  }

   void _filterServices() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredServiceTypes = List.from(_serviceTypes);
      });
    } else {
      setState(() {
        _filteredServiceTypes = _serviceTypes
            .where((service) => service['nom']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      });
    }
  }


  Future<void> _fetchSpecialites() async {
    final response = await http.get(Uri.parse(Environment.getspecialties()));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _specialites = List<Map<String, dynamic>>.from(data['specialites']);
        });
      }
    }
  }

  Future<void> _fetchSousSpecialites(String specialite) async {
    final response = await http.get(Uri.parse('${Environment.getsousspecialties()}?specialite=$specialite'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _sousSpecialites = List<Map<String, dynamic>>.from(data['sous_specialites']);
        });
      }
    }
  }

  Future<void> _fetchServiceTypes() async {
    try {
      final response = await http.get(Uri.parse(Environment.getservicetypes()));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _serviceTypes = List<Map<String, dynamic>>.from(data['service_types']);
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching service types: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load services: $e')),
      );
    }
  }

  void _addService(Map<String, dynamic> service) {
    setState(() {
      _selectedServices.add(service);
    });
  }

  void _removeService(int index) {
    setState(() {
      _selectedServices.removeAt(index);
    });
  }

  void _updateServicePrice(int index, String price) {
    setState(() {
      _selectedServices[index]['price'] = double.tryParse(price) ?? 0.0;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final doctorData = {
        'nom': _nom,
        'prenom': _prenom,
        'adresse': _adresse,
        'id_wilaya': _wilayas.firstWhere((w) => w['nom_wilaya'] == _wilaya)['id_wilaya'],
        'id_commune': _communes.firstWhere((c) => c['nom_commune'] == _commune)['id_commune'],
        'adresse_email': _email,
        'mot_de_passe': _motDePasse,
        'numero_telephone': _numeroTelephone,
        'consultation_domicile': _consultationDomicile ? 1 : 0,
        'consultation_cabinet': _consultationCabinet ? 1 : 0,
        'est_infirmier': _estInfirmier ? 1 : 0,
        'est_gm': _estGM ? 1 : 0,
        'assistant': _assistantTelephonique ? 1 : 0,
        'status': _status,
        'specialite': _specialites.firstWhere((s) => s['nom_specialite'] == _specialite)['id_specialite'],
        'sous_specialite': _sousSpecialite != null
            ? _sousSpecialites.firstWhere((s) => s['nom_sous_specialite'] == _sousSpecialite)['id_sous_specialite']
            : null,
        'services': _selectedServices.map((service) => {
          'id_service_type': service['id_service_type'],
          'price': service['price'],
        }).toList(),
      };

      try {
        final response = await http.post(
          Uri.parse(Environment.adddoctor()),
          body: json.encode(doctorData),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Doctor added successfully with all details')),
            );
            Navigator.pop(context);
          } else {
            throw Exception(responseData['message']);
          }
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add doctor: $e')),
        );
        print('Error adding doctor: $e');
      }
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter Doctor', 
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2563EB).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection(
                    title: 'Informations Personnelles',
                    icon: Icons.person_outline,
                    children: [
                      TextFormField(
                        decoration: _buildInputDecoration('Nom', Icons.person),
                        validator: (value) => value!.isEmpty ? 'Veuillez entrer un nom' : null,
                        onSaved: (value) => _nom = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: _buildInputDecoration('Prénom', Icons.person_outline),
                        validator: (value) => value!.isEmpty ? 'Veuillez entrer un prenom' : null,
                        onSaved: (value) => _prenom = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: _buildInputDecoration('Adresse', Icons.home_outlined),
                        validator: (value) => value!.isEmpty ? 'Veuillez entrer une addresse' : null,
                        onSaved: (value) => _adresse = value!,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Location',
                    icon: Icons.location_on_outlined,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: _buildInputDecoration('Wilaya', Icons.map_outlined),
                        items: _wilayas.map((wilaya) {
                          return DropdownMenuItem<String>(
                            value: wilaya['nom_wilaya'] as String,
                            child: Text(wilaya['nom_wilaya'] as String),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _wilaya = newValue;
                            _commune = null;
                            _fetchCommunes(newValue!);
                          });
                        },
                        validator: (value) => value == null ? 'Please select a wilaya' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: _buildInputDecoration('Commune', Icons.location_city_outlined),
                        items: _communes.map((commune) {
                          return DropdownMenuItem<String>(
                            value: commune['nom_commune'] as String,
                            child: Text(commune['nom_commune'] as String),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _commune = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a commune' : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Contact Information',
                    icon: Icons.contact_mail_outlined,
                    children: [
                      TextFormField(
                        decoration: _buildInputDecoration('Email', Icons.email_outlined),
                        validator: (value) => value!.isEmpty ? 'Please enter an email' : null,
                        onSaved: (value) => _email = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: _buildInputDecoration('Mot de passe', Icons.lock_outline),
                        obscureText: true,
                        validator: (value) => value!.isEmpty ? 'Please enter a password' : null,
                        onSaved: (value) => _motDePasse = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: _buildInputDecoration('Numéro de téléphone', Icons.phone_outlined),
                        validator: (value) => value!.isEmpty ? 'Please enter a phone number' : null,
                        onSaved: (value) => _numeroTelephone = value!,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Professional Information',
                    icon: Icons.work_outline,
                    children: [
                      _buildSwitchTile(
                        title: 'Consultation à domicile',
                        value: _consultationDomicile,
                        onChanged: (value) => setState(() => _consultationDomicile = value),
                        icon: Icons.home_work_outlined,
                      ),
                      _buildSwitchTile(
                        title: 'Consultation au cabinet',
                        value: _consultationCabinet,
                        onChanged: (value) => setState(() => _consultationCabinet = value),
                        icon: Icons.medical_services_outlined,
                      ),
                      _buildSwitchTile(
                        title: 'Est infirmier',
                        value: _estInfirmier,
                        onChanged: (value) => setState(() => _estInfirmier = value),
                        icon: Icons.healing_outlined,
                      ),
                      _buildSwitchTile(
                        title: 'Est garde malade',
                        value: _estGM,
                        onChanged: (value) => setState(() => _estGM = value),
                        icon: Icons.personal_injury_outlined,
                      ),
                      _buildSwitchTile(
                        title: 'Assistant téléphonique',
                        value: _assistantTelephonique,
                        onChanged: (value) => setState(() => _assistantTelephonique = value),
                        icon: Icons.support_agent_outlined,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: _buildInputDecoration('Status', Icons.toggle_on_outlined),
                        value: _status,
                        items: ['active', 'inactive'].map((String status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.capitalize()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _status = newValue!;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Specialties',
                    icon: Icons.medical_information_outlined,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: _buildInputDecoration('Spécialité', Icons.local_hospital_outlined),
                        items: _specialites.map((specialite) {
                          return DropdownMenuItem<String>(
                            value: specialite['nom_specialite'] as String,
                            child: Text(specialite['nom_specialite'] as String),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _specialite = newValue;
                            _sousSpecialite = null;
                            _fetchSousSpecialites(newValue!);
                          });
                        },
                        validator: (value) => value == null ? 'Please select a speciality' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: _buildInputDecoration('Sous-spécialité', Icons.bookmark_outline),
                        items: _sousSpecialites.map((sousSpecialite) {
                          return DropdownMenuItem<String>(
                            value: sousSpecialite['nom_sous_specialite'] as String,
                            child: Text(sousSpecialite['nom_sous_specialite'] as String),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _sousSpecialite = newValue;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Services',
                    icon: Icons.medical_services_outlined,
                    children: [
                      _buildServicesExpansionTile(),
                      const SizedBox(height: 16),
                      _buildSelectedServicesList(),
                    ],
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ajouter le docteur',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB)),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF6B7280)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2563EB),
      ),
    );
  }

Widget _buildServicesExpansionTile() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text(
            'Services fournis',
            style: TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
              if (expanded) {
                _filteredServiceTypes = List.from(_serviceTypes);
              }
            });
          },
          initiallyExpanded: _isExpanded,
          children: [
            if (_serviceTypes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un service...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredServiceTypes.length,
                    itemBuilder: (context, index) {
                      final service = _filteredServiceTypes[index];
                      return ListTile(
                        leading: const Icon(Icons.medical_services_outlined),
                        title: Text(service['nom'].toString()),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: const Color(0xFF2563EB),
                          onPressed: () {
                            _addService({
                              'id_service_type': service['id_service_type'],
                              'nom': service['nom'],
                              'price': service['has_fixed_price'] == 1
                                  ? double.parse(service['fixed_price'].toString())
                                  : 0.0,
                            });
                            setState(() {
                              _isExpanded = false;
                              _searchController.clear();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedServicesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Services',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedServices.length,
          itemBuilder: (context, index) {
final service = _selectedServices[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.medical_services_outlined,
                  color: Color(0xFF6B7280),
                ),
                title: Text(
                  service['nom'],
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        initialValue: service['price'].toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            service['price'] = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Color(0xFFEF4444),
                      ),
                      onPressed: () => _removeService(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}