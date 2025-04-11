import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class BookRidePage extends StatefulWidget {
  const BookRidePage({super.key});

  @override
  State<BookRidePage> createState() => _BookRidePageState();
}

class _BookRidePageState extends State<BookRidePage> {
  late GoogleMapController _mapController; // Controller for the Google Map
  LatLng _currentLocation = const LatLng(37.7749, -122.4194); // Default to San Francisco
  LatLng? _destination; // Selected destination on the map
  bool _isLoading = true; // Indicates if the current location is being loaded

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Get the user's current location when the page is initialized
  }

  // Method to get the user's current location
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch current location.')),
        );
      }
    }
  }

  // Method called when the map is tapped
  void _onMapTapped(LatLng position) {
    if (mounted) {
      setState(() {
        _destination = position;
      });
    }
  }

  // Method to confirm the ride
  void _confirmRide() {
    if (mounted) {
      if (_destination != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ride confirmed to ${_destination!.latitude}, ${_destination!.longitude}!',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a destination.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('currentLocation'),
                      position: _currentLocation,
                      infoWindow: const InfoWindow(title: 'Your Location'),
                    ),
                    if (_destination != null)
                      Marker(
                        markerId: const MarkerId('destination'),
                        position: _destination!,
                        infoWindow: const InfoWindow(title: 'Destination'),
                      ),
                  },
                  onTap: _onMapTapped,
                ),
                if (_destination != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: _confirmRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Ride',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}