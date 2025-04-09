import 'package:flutter/material.dart';

class RideMatchPage extends StatelessWidget {
  const RideMatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Ride Match'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Find the best ride matches for you!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add functionality to find ride matches
              },
              child: const Text('Find Matches'),
            ),
          ],
        ),
      ),
    );
  }
}