import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../config/environment.dart';

import 'package:path/path.dart' as path;

class AddServicesScreen extends StatefulWidget {
  const AddServicesScreen({super.key});

  @override
  _AddServicesScreenState createState() => _AddServicesScreenState();
}

class _AddServicesScreenState extends State<AddServicesScreen> {
  final _formKey = GlobalKey<FormState>();
  String _serviceName = '';
  bool _hasFixedPrice = true;
  double _fixedPrice = 0.0;
  File? _image;
  final picker = ImagePicker();

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(Environment.addservice()),
      );

      request.fields['nom'] = _serviceName;
      request.fields['has_fixed_price'] = _hasFixedPrice ? '1' : '0';
      request.fields['fixed_price'] = _fixedPrice.toString();

      if (_image != null) {
        String extension = path.extension(_image!.path);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _image!.path,
          filename: '${_serviceName.replaceAll(' ', '_').toLowerCase()}$extension',
        ));
      }

      try {
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          if (response.body.isNotEmpty) {
            try {
              var jsonResponse = json.decode(response.body);
              if (jsonResponse['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Service added successfully')),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(jsonResponse['message'] ?? 'Unknown error occurred')),
                );
              }
            } catch (e) {
              print('Error decoding JSON: $e');
              print('Raw response: ${response.body}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error processing server response: $e')),
              );
            }
          } else {
            print('Error: Empty response body');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Server returned an empty response')),
            );
          }
        } else {
          print('Error: Non-200 status code');
          print('Response body: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error: ${response.statusCode}\n${response.body}')),
          );
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un service'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Nom du service',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez saisir un nom de service';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _serviceName = value!;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('A un prix fixe'),
                  value: _hasFixedPrice,
                  onChanged: (bool value) {
                    setState(() {
                      _hasFixedPrice = value;
                    });
                  },
                  activeColor: Colors.teal,
                ),
                const SizedBox(height: 16),
                if (_hasFixedPrice)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'prix fixe',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a fixed price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _fixedPrice = double.parse(value!);
                    },
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _getImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Selectionner Image'),
                ),
                const SizedBox(height: 16),
                if (_image != null)
                  Image.file(
                    _image!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Ajouter Service'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}