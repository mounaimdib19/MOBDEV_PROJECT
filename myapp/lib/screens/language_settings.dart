import 'package:flutter/material.dart';

class LanguageSettings extends StatelessWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Languages'),
        backgroundColor: const Color(0xFF1B5A90),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'This page allows users to select their preferred language. '
          'Implement language selection options here.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}