// @dart=2.19

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  bool _isLoading = false;
  Position? _currentPosition;
  final _places = GoogleMapsPlaces(apiKey: 'AIzaSyCPmf03XcowTuWeMD7n43LAV7CeJ5cA3bs');
  List<Map<String, dynamic>> _emergencyContacts = [];
  List<Map<String, dynamic>> _nearbyPoliceStations = [];
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadEmergencyContacts();
  }

  @override
  void dispose() {
    _parentPhoneController.dispose();
    _parentNameController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _emergencyContacts = [
              {'name': 'Police', 'number': '100'},
              {'name': 'Ambulance', 'number': '108'},
              {'name': 'Fire', 'number': '101'},
              if (data?['parentName'] != null && data?['parentPhone'] != null)
                {
                  'name': data!['parentName'],
                  'number': data['parentPhone'],
                },
            ];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
      _findNearbyPoliceStations();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _findNearbyPoliceStations() async {
    if (_currentPosition == null) return;

    try {
      final response = await _places.searchNearbyWithRadius(
        Location(lat: _currentPosition!.latitude, lng: _currentPosition!.longitude),
        5000, // 5km radius
        type: 'police',
      );

      if (response.isOkay) {
        setState(() {
          _nearbyPoliceStations = response.results.map((place) => {
            'name': place.name,
            'address': place.vicinity,
            'phone': 'Contact Emergency Services',
            'distance': '${(place.geometry?.location.lat ?? 0).toStringAsFixed(2)} km',
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding police stations: $e')),
        );
      }
    }
  }

  Future<void> _makeEmergencyCall(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not make the call')),
      );
    }
  }

  Future<void> _saveParentContact() async {
    if (_parentNameController.text.isEmpty || _parentPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'parentName': _parentNameController.text,
          'parentPhone': _parentPhoneController.text,
        });
        _loadEmergencyContacts();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parent contact saved successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving contact: $e')),
      );
    }
  }

  void _showAddParentContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Parent Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _parentNameController,
              decoration: const InputDecoration(
                labelText: 'Parent Name',
                hintText: 'Enter parent name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _parentPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveParentContact,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm SOS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to send an SOS alert?'),
            if (_currentPosition != null) ...[
              const SizedBox(height: 16),
              const Text('Your current location:'),
              Text('Latitude: ${_currentPosition!.latitude}'),
              Text('Longitude: ${_currentPosition!.longitude}'),
            ],
            if (_nearbyPoliceStations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Nearby Police Stations:'),
              ..._nearbyPoliceStations.map((station) => ListTile(
                title: Text(station['name']),
                subtitle: Text(station['address']),
                trailing: station['phone'] != null
                    ? IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () => _makeEmergencyCall(station['phone']),
                      )
                    : null,
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Call all emergency contacts
              for (var contact in _emergencyContacts) {
                _makeEmergencyCall(contact['number']);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SOS Alert Triggered!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS'),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SOS Button
                  ElevatedButton(
                    onPressed: _triggerSOS,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Emergency Contacts
                  const Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._emergencyContacts.map((contact) => Card(
                        child: ListTile(
                          title: Text(contact['name']),
                          trailing: IconButton(
                            icon: const Icon(Icons.phone),
                            onPressed: () => _makeEmergencyCall(contact['number']),
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showAddParentContactDialog,
                    child: const Text('Add Parent Contact'),
                  ),
                  const SizedBox(height: 24),
                  // Nearby Police Stations
                  const Text(
                    'Nearby Police Stations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_nearbyPoliceStations.isEmpty)
                    const Center(
                      child: Text('No police stations found nearby'),
                    )
                  else
                    ..._nearbyPoliceStations.map((station) => Card(
                          child: ListTile(
                            title: Text(station['name']),
                            subtitle: Text(station['address']),
                            trailing: station['phone'] != null
                                ? IconButton(
                                    icon: const Icon(Icons.phone),
                                    onPressed: () =>
                                        _makeEmergencyCall(station['phone']),
                                  )
                                : null,
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}