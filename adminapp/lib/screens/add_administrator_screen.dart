// add_administrator_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

class AddAdministratorScreen extends StatefulWidget {
  const AddAdministratorScreen({super.key});

  @override
  _AddAdministratorScreenState createState() => _AddAdministratorScreenState();
}

class _AddAdministratorScreenState extends State<AddAdministratorScreen> {
  final _formKey = GlobalKey<FormState>();
  String nom = '';
  String prenom = '';
  String email = '';
  String password = '';
  String type = 'admin';
  String statut = 'active';

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final response = await http.post(
        Uri.parse(Environment.addadmin()),
        body: {
          'nom': nom,
          'prenom': prenom,
          'adresse_email': email,
          'mot_de_passe': password,
          'type': type,
          'statut': statut,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Administrator added successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add administrator: ${result['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to the server')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Administrator'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value!.isEmpty ? 'Please enter first name' : null,
                onSaved: (value) => prenom = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value!.isEmpty ? 'Please enter last name' : null,
                onSaved: (value) => nom = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Please enter email' : null,
                onSaved: (value) => email = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Please enter password' : null,
                onSaved: (value) => password = value!,
              ),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['admin', 'superadmin'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    type = newValue!;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: statut,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['active', 'inactive'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    statut = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Add Administrator'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}