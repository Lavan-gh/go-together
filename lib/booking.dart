import 'package:flutter/material.dart';

class RideBookingPage extends StatefulWidget {
  const RideBookingPage({super.key});

  @override
  State<RideBookingPage> createState() => _RideBookingPageState();
}

class _RideBookingPageState extends State<RideBookingPage> {
  // Controllers for the pickup and drop-off text fields
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();

  @override
  void dispose() {
    // Dispose of the controllers when the widget is removed from the widget tree
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  // Method to handle the booking of a ride
  void _bookRide() {
    // Check if either the pickup or drop-off field is empty
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      // Show a SnackBar with an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both pickup and drop-off locations.'),
        ),
      );
    } else {
      // Show a SnackBar with a success message, including the pickup and drop-off locations
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Ride booked from ${_pickupController.text} to ${_dropoffController.text}!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TextField for pickup location
            TextField(
              controller: _pickupController,
              decoration: const InputDecoration(
                labelText: 'Pickup Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // TextField for drop-off location
            TextField(
              controller: _dropoffController,
              decoration: const InputDecoration(
                labelText: 'Drop-off Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // Button to book the ride
            ElevatedButton(
              onPressed: _bookRide,
              child: const Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }
}