import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Properties
  CameraPosition _currentCameraPosition = const CameraPosition(
    target: LatLng(16.329363002332755, 79.71954055875539),
    zoom: 15,
  );
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  int _selectedSeats = 1;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  // Initialize state
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Dispose controllers
  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied')),
        );
        return;
      }

      final Position currentPosition = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentCameraPosition = CameraPosition(
          target: LatLng(currentPosition.latitude, currentPosition.longitude),
          zoom: 15,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get location')),
      );
    }
  }

    // Select date and time
  Future<void> _selectDateAndTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Increment seats
  void _incrementSeats() {
    setState(() {
      _selectedSeats++;
    });
  }

  // Decrement seats
  void _decrementSeats() {
    setState(() {
      if (_selectedSeats > 1) {
        _selectedSeats--;
      }
    });
  }

  // Swap source and destination
  void _swapSourceDestination() {
    final temp = _sourceController.text;
    _sourceController.text = _destinationController.text;
    _destinationController.text = temp;
  }

  // Request ride
  void _requestRide() {
    if (mounted) {
      final String sourceAddress = _sourceController.text;
      final String destinationAddress = _destinationController.text;

      if (sourceAddress.isEmpty || destinationAddress.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please enter both source and destination addresses.')),
        );
        return;
      }

      print('Source Address: $sourceAddress');
      print('Destination Address: $destinationAddress');
      print('Selected Date and Time: $_selectedDateTime');
      print('Number of Seats: $_selectedSeats');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride requested')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'), // App bar title
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(
              height: 200, // Adjust the height as needed
              child: GoogleMap(
                initialCameraPosition: _currentCameraPosition,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  // You can use the controller to manipulate the map
                  // For example, to move the camera:
                  // controller.animateCamera(CameraUpdate.newLatLng(_currentCameraPosition.target));
                },
              ),
            ),
            // Source and Destination Row
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _sourceController,
                      decoration: const InputDecoration(
                        hintText: 'Enter source address',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _swapSourceDestination,
                  icon: const Icon(Icons.swap_horiz),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _destinationController,
                      decoration: const InputDecoration(
                        hintText: 'Enter destination address',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Car, Bike, Rider Row
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (user?.emailVerified == true)
                    TextButton(
                      onPressed: () {},
                      child: const Text('Car'),
                    ),
                  if (user?.emailVerified == true)
                    TextButton(
                      onPressed: () {},
                      child: const Text('Bike'),
                    ),
                  const TextButton(
                    onPressed: null,
                    child: Text('Rider'),
                  ),
                ],
              ),
            ),
            // Date and Time Row
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Date/Time:'),
                  TextButton(
                    onPressed: () => _selectDateAndTime(context),
                    child: Text(
                      _dateFormat.format(_selectedDateTime),
                    ),
                  ),
                ],
              ),
            ),
            // Seats Row
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Seats:'),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _decrementSeats,
                  ),
                  Text('$_selectedSeats'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _incrementSeats,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Request Ride Button
            ElevatedButton(
              onPressed: _requestRide,
              child: const Text('Request Ride'),
            ),
          ],
        ),
      ),
    );
  }
}