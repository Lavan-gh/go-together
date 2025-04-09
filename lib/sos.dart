import 'package:flutter/material.dart';

class SOSPage extends StatelessWidget {
  const SOSPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
      ),
      body: const Center(
        child: Text(
          'SOS Page Content',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}