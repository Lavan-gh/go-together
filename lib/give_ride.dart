// @dart=2.19

import 'package:flutter/material.dart';

class GiveRidePage extends StatelessWidget {
  const GiveRidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Give a Ride'), // App bar title
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TextField for Pickup Location
            const TextField(
              decoration: InputDecoration(
                labelText: 'Pickup Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // TextField for Drop-off Location
            const TextField(
              decoration: InputDecoration(
                labelText: 'Drop-off Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // TextField for Number of Seats Available
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number of Seats Available',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // Button to submit ride details
            ElevatedButton(
              onPressed: () {
                // Show a SnackBar when the button is pressed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ride details submitted!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Ride',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}