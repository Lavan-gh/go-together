import 'package:flutter/material.dart';

class RideBookingPage extends StatefulWidget {
  const RideBookingPage({super.key});

  @override
  State<RideBookingPage> createState() => _RideBookingPageState();
}

class _RideBookingPageState extends State<RideBookingPage> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _bookRide() {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both pickup and drop-off locations.')),
      );
      return;
    }

    // Add functionality to book a ride
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ride booked from ${_pickupController.text} to ${_dropoffController.text}!')),
    );
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
            TextField(
              controller: _pickupController,
              decoration: const InputDecoration(
                labelText: 'Pickup Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _dropoffController,
              decoration: const InputDecoration(
                labelText: 'Drop-off Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
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