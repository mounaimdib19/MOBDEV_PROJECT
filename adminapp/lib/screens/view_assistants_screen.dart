import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';


class ViewAssistantsScreen extends StatefulWidget {
  const ViewAssistantsScreen({super.key});

  @override
  _ViewAssistantsScreenState createState() => _ViewAssistantsScreenState();
}

class _ViewAssistantsScreenState extends State<ViewAssistantsScreen> {
  List<dynamic> assistants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAssistants();
  }

  Future<void> fetchAssistants() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse(Environment.viewAssistants()),
    );

    if (response.statusCode == 200) {
      setState(() {
        assistants = json.decode(response.body)['records'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load assistants')),
      );
    }
  }

  Future<void> deleteAssistant(int id) async {
    final response = await http.post(
      Uri.parse(Environment.deleterecord()),
      body: json.encode({
        'table': 'docteur',
        'id': id,
        'id_column': 'id_doc',
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assistant deleted successfully')),
      );
      fetchAssistants();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete assistant')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Assistants'),
        backgroundColor: Colors.indigo,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : assistants.isEmpty
              ? const Center(child: Text('No assistants found'))
              : ListView.builder(
                  itemCount: assistants.length,
                  itemBuilder: (context, index) {
                    final assistant = assistants[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text('${assistant['nom']} ${assistant['prenom']}'),
                        subtitle: Text(assistant['adresse_email']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: const Text('Are you sure you want to delete this assistant?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('Delete'),
                                      onPressed: () {
                                        deleteAssistant(assistant['id_doc']);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}