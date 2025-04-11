// @dart=2.19

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  bool _isLoading = true;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Get the user's current location when the page is initialized
    _getNearbyPlaces();
  }

  // Method to get the user's current location
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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

  // Method to move the camera to the current location
  void _goToCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition( 
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
    );
    _mapController.animateCamera(CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude)));
  }

  Future<void> _getNearbyPlaces() async {
    const apiKey = 'AIzaSyCPmf03XcowTuWeMD7n43LAV7CeJ5cA3bs';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentLocation.latitude},${_currentLocation.longitude}&radius=1500&key=$apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to fetch nearby places: API Error.')),
          );
        }
        return;
      }

      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> places = jsonResponse['results'];

      if (mounted) {
        setState(() {
          for (var place in places) {
            final name = place['name'];
            final location = place['geometry']['location'];
            final latLng = LatLng(location['lat'], location['lng']);

            _markers.add(
              Marker(
                markerId: MarkerId(name),
                position: latLng,
                infoWindow: InfoWindow(title: name),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch nearby places.')),
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
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 14.0,
                  ),
                  onTap: _onMapTapped, markers: _markers.toSet(),
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
                Positioned(
                  bottom: 100,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _goToCurrentLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.teal,
                    ),
                  ),
                ),]
            ));
  }
}