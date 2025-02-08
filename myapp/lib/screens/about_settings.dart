import 'package:flutter/material.dart';

class AboutSettings extends StatelessWidget {
  const AboutSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: const Color(0xFF1B5A90),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'This page contains information about the app, including version number, '
          'developer information, and any other relevant details.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}