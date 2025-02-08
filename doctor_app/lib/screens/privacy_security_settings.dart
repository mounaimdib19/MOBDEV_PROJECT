import 'package:flutter/material.dart';

class PrivacySecuritySettings extends StatelessWidget {
  const PrivacySecuritySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confidentialité et sécurité'),
        backgroundColor: const Color.fromARGB(255, 37, 144, 27),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Cette page contient des informations sur les paramètres de confidentialité et de sécurité. '
          'Implémentez ici des options spécifiques de confidentialité et de sécurité.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}