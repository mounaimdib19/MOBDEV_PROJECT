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

  @override
  void initState() {
    super.initState();
    _fetchWilayas();
    _fetchSpecialites();
    _fetchServiceTypes();
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
        title: const Text('Add Doctor'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Nom',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                            onSaved: (value) => _nom = value!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Prénom',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value!.isEmpty ? 'Please enter a first name' : null,
                            onSaved: (value) => _prenom = value!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Adresse',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value!.isEmpty ? 'Please enter an address' : null,
                            onSaved: (value) => _adresse = value!,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Wilaya',
                              border: OutlineInputBorder(),
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'Commune',
                              border: OutlineInputBorder(),
                            ),
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value!.isEmpty ? 'Please enter an email' : null,
                            onSaved: (value) => _email = value!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) => value!.isEmpty ? 'Please enter a password' : null,
                            onSaved: (value) => _motDePasse = value!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Numéro de téléphone',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value!.isEmpty ? 'Please enter a phone number' : null,
                            onSaved: (value) => _numeroTelephone = value!,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Professional Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          CheckboxListTile(
                            title: const Text('Consultation à domicile'),
                            value: _consultationDomicile,
                            onChanged: (bool? value) {
                              setState(() {
                                _consultationDomicile = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Consultation au cabinet'),
                            value: _consultationCabinet,
                            onChanged: (bool? value) {
                              setState(() {
                                _consultationCabinet = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Est infirmier'),
                            value: _estInfirmier,
                            onChanged: (bool? value) {
                              setState(() {
                                _estInfirmier = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Est garde malade'),
                            value: _estGM,
                            onChanged: (bool? value) {
                              setState(() {
                                _estGM = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Assistant téléphonique'),
                            value: _assistantTelephonique,
                            onChanged: (bool? value) {
                              setState(() {
                                _assistantTelephonique = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            value: _status,
                            items: ['active', 'inactive'].map((String status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Specialties',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Spécialité',
                              border: OutlineInputBorder(),
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'Sous-spécialité',
                              border: OutlineInputBorder(),
                            ),
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Services',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: const Text('Available Services'),
                            children: [
                              if (_serviceTypes.isEmpty)
                                const ListTile(title: Text('Loading services...')),
                              if (_serviceTypes.isNotEmpty && _serviceTypes[0].containsKey('nom') && _serviceTypes[0]['nom'].startsWith('Error'))
                                ListTile(
                                  title: Text(_serviceTypes[0]['nom'], style: const TextStyle(color: Colors.red)),
                                  subtitle: const Text('Check console for more details', style: TextStyle(color: Colors.red)),
                                ),
                              ..._serviceTypes.where((service) => !service['nom'].toString().startsWith('Error')).map((serviceType) {
                                return ListTile(
                                  title: Text(serviceType['nom'].toString()),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      _addService({
                                        'id_service_type': serviceType['id_service_type'],
                                        'nom': serviceType['nom'],
                                        'price': serviceType['has_fixed_price'] == 1 ? double.parse(serviceType['fixed_price'].toString()) : 0.0,
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Selected Services',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedServices.length,
                            itemBuilder: (context, index) {
                              final service = _selectedServices[index];
                              return ListTile(
                                title: Text(service['nom']),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        initialValue: service['price'].toString(),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          setState(() {
                                            service['price'] = double.tryParse(value) ?? 0;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          labelText: 'Price',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () => _removeService(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
  onPressed: _submitForm,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
  ),
  child: const Text('Add Doctor'),
),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}