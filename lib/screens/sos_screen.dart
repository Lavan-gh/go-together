import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/api_keys.dart';

class SOSScreen extends StatefulWidget {
  @override
  _SOSScreenState createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _isLoading = false;
  Position? _currentPosition;
  String? _nearestPoliceStation;
  String? _policeStationAddress;
  String? _policeStationPhone;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);
      await _findNearestPoliceStation(position);
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _findNearestPoliceStation(Position position) async {
    final places = GoogleMapsPlaces(apiKey: APIKeys.googleMapsKey);
    final response = await places.searchNearbyWithRadius(
      Location(lat: position.latitude, lng: position.longitude),
      5000, // 5km radius
      type: 'police',
    );

    if (response.status == 'OK' && response.results.isNotEmpty) {
      final nearestStation = response.results.first;
      setState(() {
        _nearestPoliceStation = nearestStation.name;
        _policeStationAddress = nearestStation.vicinity;
        _policeStationPhone = null;
      });
    }
  }

  Future<void> _sendEmergencyAlert() async {
    if (_currentPosition == null) return;

    setState(() => _isLoading = true);
    try {
      // Save emergency alert to Firestore
      await FirebaseFirestore.instance.collection('emergency_alerts').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'location': GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
        'status': 'active',
        'policeStation': _nearestPoliceStation,
        'policeStationAddress': _policeStationAddress,
        'policeStationPhone': _policeStationPhone,
      });

      // Call police station if phone number is available
      if (_policeStationPhone != null) {
        final url = 'tel:${_policeStationPhone!.replaceAll(RegExp(r'[^0-9+]'), '')}';
        if (await canLaunch(url)) {
          await launch(url);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emergency alert sent successfully!')),
      );
    } catch (e) {
      print('Error sending emergency alert: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending emergency alert')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency SOS'),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emergency,
                            size: 64,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Emergency SOS',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Press the button below to send an emergency alert to the nearest police station',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  if (_nearestPoliceStation != null) ...[
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.local_police),
                        title: Text('Nearest Police Station'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_nearestPoliceStation!),
                            if (_policeStationAddress != null)
                              Text(_policeStationAddress!),
                            if (_policeStationPhone != null)
                              Text(_policeStationPhone!),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: _sendEmergencyAlert,
                    child: Text('SEND EMERGENCY ALERT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your current location will be shared with the police station',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
} 