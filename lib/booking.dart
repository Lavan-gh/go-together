import 'package:flutter/material.dart';

class RideBookingPage extends StatelessWidget {
  const RideBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your pickup and drop-off locations.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add functionality to book a ride
              },
              child: const Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }
}