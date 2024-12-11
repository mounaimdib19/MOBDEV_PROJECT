import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';


class GenericDeleteScreen extends StatefulWidget {
  final String title;
  final String entityType;
  final String tableName;
  final String idColumnName;
  final String apiUrl;

  const GenericDeleteScreen({super.key, 
    required this.title,
    required this.entityType,
    required this.tableName,
    required this.idColumnName,
    required this.apiUrl,
  });

  @override
  _GenericDeleteScreenState createState() => _GenericDeleteScreenState();
}

class _GenericDeleteScreenState extends State<GenericDeleteScreen> {
  List<dynamic> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(Uri.parse(widget.apiUrl));

    if (response.statusCode == 200) {
      setState(() {
        items = json.decode(response.body)['records'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load ${widget.entityType}s')),
      );
    }
  }

  Future<void> deleteItem(int id) async {
    final response = await http.post(
      Uri.parse(Environment.deleterecord()),
      body: json.encode({
        'table': widget.tableName,
        'id': id,
        'id_column': widget.idColumnName,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.entityType} deleted successfully')),
      );
      fetchItems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete ${widget.entityType}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.indigo,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(child: Text('No ${widget.entityType}s found'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(item['nom'] + ' ' + item['prenom']),
                        subtitle: Text(item['adresse_email'] ?? 'No email'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text('Are you sure you want to delete this ${widget.entityType}?'),
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
                                        deleteItem(item[widget.idColumnName]);
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