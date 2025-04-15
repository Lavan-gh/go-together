import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_maps_webservice/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestRideScreen extends StatefulWidget {
  @override
  _RequestRideScreenState createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _seatsController = TextEditingController();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  LatLng? _sourceLocation;
  LatLng? _destinationLocation;
  bool _isLoading = false;
  List<Prediction> _placePredictions = [];
  String _sourceAddress = '';
  String _destinationAddress = '';

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
      setState(() {
        _currentPosition = position;
        _markers.add(
          Marker(
            markerId: MarkerId('current'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(title: 'Current Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
      await _getAddressFromLatLng(LatLng(position.latitude, position.longitude));
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    final geocoding = GoogleMapsGeocoding(apiKey: 'YOUR_API_KEY');
    final response = await geocoding.searchByLocation(
      Location(lat: latLng.latitude, lng: latLng.longitude),
    );

    if (response.status == 'OK') {
      final result = response.results.first;
      String address = result.formattedAddress ?? '';
      setState(() {
        if (_sourceLocation == latLng) {
          _sourceAddress = address;
        } else if (_destinationLocation == latLng) {
          _destinationAddress = address;
        }
      });
    }
  }

  Future<void> _searchPlaces(String query, bool isSource) async {
    if (query.isEmpty) {
      setState(() => _placePredictions = []);
      return;
    }

    final places = GoogleMapsPlaces(apiKey: 'YOUR_API_KEY');
    final response = await places.autocomplete(query);

    if (response.status == 'OK') {
      setState(() => _placePredictions = response.predictions);
    }
  }

  Future<void> _selectPlace(Prediction prediction, bool isSource) async {
    final places = GoogleMapsPlaces(apiKey: 'YOUR_API_KEY');
    final details = await places.getDetailsByPlaceId(prediction.placeId!);

    if (details.status == 'OK') {
      final place = details.result;
      final location = LatLng(
        place.geometry!.location.lat,
        place.geometry!.location.lng,
      );

      setState(() {
        if (isSource) {
          _sourceLocation = location;
          _sourceController.text = prediction.description!;
          _markers.removeWhere((m) => m.markerId.value == 'source');
          _markers.add(
            Marker(
              markerId: MarkerId('source'),
              position: location,
              infoWindow: InfoWindow(title: 'Source'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              draggable: true,
              onDragEnd: (newPosition) {
                _sourceLocation = newPosition;
                _getAddressFromLatLng(newPosition);
              },
            ),
          );
        } else {
          _destinationLocation = location;
          _destinationController.text = prediction.description!;
          _markers.removeWhere((m) => m.markerId.value == 'destination');
          _markers.add(
            Marker(
              markerId: MarkerId('destination'),
              position: location,
              infoWindow: InfoWindow(title: 'Destination'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              draggable: true,
              onDragEnd: (newPosition) {
                _destinationLocation = newPosition;
                _getAddressFromLatLng(newPosition);
              },
            ),
          );
        }
        _placePredictions = [];
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15),
      );
      await _getAddressFromLatLng(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request a Ride'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null
                          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                          : LatLng(0, 0),
                      zoom: 15,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _sourceController,
                                decoration: InputDecoration(
                                  labelText: 'Source',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.my_location),
                                    onPressed: () async {
                                      await _getCurrentLocation();
                                      if (_currentPosition != null) {
                                        _sourceLocation = LatLng(
                                          _currentPosition!.latitude,
                                          _currentPosition!.longitude,
                                        );
                                        _sourceController.text = _sourceAddress;
                                      }
                                    },
                                  ),
                                ),
                                onChanged: (value) => _searchPlaces(value, true),
                              ),
                            ),
                          ],
                        ),
                        if (_placePredictions.isNotEmpty)
                          Container(
                            height: 200,
                            child: ListView.builder(
                              itemCount: _placePredictions.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_placePredictions[index].description!),
                                  onTap: () => _selectPlace(_placePredictions[index], true),
                                );
                              },
                            ),
                          ),
                        if (_sourceAddress.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _sourceAddress,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _destinationController,
                          decoration: InputDecoration(
                            labelText: 'Destination',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          onChanged: (value) => _searchPlaces(value, false),
                        ),
                        if (_placePredictions.isNotEmpty)
                          Container(
                            height: 200,
                            child: ListView.builder(
                              itemCount: _placePredictions.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_placePredictions[index].description!),
                                  onTap: () => _selectPlace(_placePredictions[index], false),
                                );
                              },
                            ),
                          ),
                        if (_destinationAddress.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _destinationAddress,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dateController,
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(Duration(days: 30)),
                                  );
                                  if (date != null) {
                                    _dateController.text = date.toString().split(' ')[0];
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _timeController,
                                decoration: InputDecoration(
                                  labelText: 'Time',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    _timeController.text = time.format(context);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _seatsController,
                          decoration: InputDecoration(
                            labelText: 'Number of Seats',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.event_seat),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter number of seats';
                            }
                            if (int.tryParse(value) == null || int.parse(value) < 1) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _requestRide,
                          child: Text('Request Ride'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: 'CO2 Tracker',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/co2_tracker');
              break;
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/sos');
        },
        child: Icon(Icons.emergency),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _requestRide() {
    if (_formKey.currentState!.validate() && _sourceLocation != null && _destinationLocation != null) {
      // TODO: Implement ride request logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Requesting your ride...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select source and destination locations')),
      );
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _seatsController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
} 