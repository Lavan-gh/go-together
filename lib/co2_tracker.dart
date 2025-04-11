import 'package:flutter/material.dart';

class CO2TrackerPage extends StatelessWidget {
  const CO2TrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CO2 Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title text
            const Text(
              'Track your CO2 emissions and savings here!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Description text
            const Text(
              'This feature will allow you to monitor your environmental impact by tracking the CO2 emissions saved through carpooling.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Button to trigger CO2 tracking functionality
            ElevatedButton(
              onPressed: () {
                // Show a SnackBar when the button is pressed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CO2 Tracker functionality coming soon!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Track CO2 Savings',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}