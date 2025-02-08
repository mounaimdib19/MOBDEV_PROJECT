import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../config/environment.dart';


class EditServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const EditServiceScreen({super.key, required this.service});

  @override
  _EditServiceScreenState createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _serviceName;
  late bool _hasFixedPrice;
  late double _fixedPrice;
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _serviceName = widget.service['nom'];
    _hasFixedPrice = widget.service['has_fixed_price'] == '1';
    _fixedPrice = double.tryParse(widget.service['fixed_price'] ?? '0') ?? 0.0;
  }

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
        Uri.parse(Environment.updateservice()),
      );

      request.fields['id_service_type'] = widget.service['id_service_type'].toString();
      request.fields['nom'] = _serviceName;
      request.fields['has_fixed_price'] = _hasFixedPrice ? '1' : '0';
      request.fields['fixed_price'] = _fixedPrice.toString();

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'picture',
          _image!.path,
        ));
      }

      try {
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          var jsonResponse = json.decode(response.body);
          if (jsonResponse['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Service updated successfully')),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(jsonResponse['message'] ?? 'Unknown error occurred')),
            );
          }
        } else {
          print('Error: ${response.statusCode}');
          print('Response body: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update service. Please try again.')),
          );
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please check your connection and try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('édition de service'),
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
                  initialValue: _serviceName,
                  decoration: InputDecoration(
                    labelText: 'Nom du service',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a service name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _serviceName = value!;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('A un prix fixe?'),
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
                    initialValue: _fixedPrice.toString(),
                    decoration: InputDecoration(
                      labelText: 'Fixed Price',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez saisir un prix fixe';
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
                  child: const Text('Select New Image'),
                ),
                const SizedBox(height: 16),
                if (_image != null)
                  Image.file(
                    _image!,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                else if (widget.service['picture_url'] != null)
                  Image.network(
                    'http://10.80.2.184/siteweb22/upload/services/${widget.service['picture_url']}',
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Failed to load image');
                    },
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Update Service'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}