// @dart=2.19

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'request_ride.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookRidePage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const BookRidePage({Key? key, required this.arguments}) : super(key: key);

  @override
  State<BookRidePage> createState() => _BookRidePageState();
}

<<<<<<< HEAD
class _BookRidePageState extends State<BookRidePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  bool _isLoading = false;
  String _selectedVehicleType = 'Car';
  int _selectedSeats = 1;
  DateTime _selectedDateTime = DateTime.now();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');
  double _estimatedFare = 0.0;
  bool _isFareCalculated = false;
  List<Prediction> _pickupPredictions = [];
  List<Prediction> _dropoffPredictions = [];
  final _places = GoogleMapsPlaces(apiKey: 'AIzaSyCPmf03XcowTuWeMD7n43LAV7CeJ5cA3bs');
  BitmapDescriptor? _personMarkerIcon;
  BitmapDescriptor? _bikeMarkerIcon;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String? _estimatedTime;
  double? _estimatedDistance;
  List<Map<String, dynamic>> _availableRides = [];
  final _searchController = TextEditingController();
=======
class _BookRidePageState extends State<BookRidePage> {
  late GoogleMapController _mapController; // Controller for the Google Map
  LatLng _currentLocation = const LatLng(37.7749, -122.4194); // Default to San Francisco
  LatLng? _destination; // Selected destination on the map
  bool _isLoading = true;
  final Set<Marker> _markers = {};
>>>>>>> f822eaa09bbf8b284bad692aaf862a2b4735e9c4

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
    _loadMarkerIcons();
    _loadAvailableRides();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _searchController.dispose();
    super.dispose();
=======
    _getCurrentLocation(); // Get the user's current location when the page is initialized
    _getNearbyPlaces();
>>>>>>> f822eaa09bbf8b284bad692aaf862a2b4735e9c4
  }

  // Method to get the user's current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
      }
      return;
    }

    // Get current position
    try {
<<<<<<< HEAD
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Current Location'),
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }

  Future<void> _calculateFare() async {
    if (_currentPosition == null) return;

    // Simulate fare calculation based on distance
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _estimatedFare = 50.0 + (_selectedSeats * 10.0);
        _isFareCalculated = true;
=======
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
>>>>>>> f822eaa09bbf8b284bad692aaf862a2b4735e9c4
      });
    }
  }

<<<<<<< HEAD
  Future<void> _selectDateAndTime() async {
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

  // Method to confirm the ride
  void _confirmRide() {
    if (_currentPosition != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Ride'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehicle Type: $_selectedVehicleType'),
              Text('Seats: $_selectedSeats'),
              Text('Date/Time: ${_dateFormat.format(_selectedDateTime)}'),
              Text('Estimated Fare: \$${_estimatedFare.toStringAsFixed(2)}'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ride confirmed!')),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination.')),
      );
=======
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
>>>>>>> f822eaa09bbf8b284bad692aaf862a2b4735e9c4
    }
  }

  Future<void> _loadMarkerIcons() async {
    final personSvgString = await rootBundle.loadString('assets/images/person_marker.svg');
    final bikeSvgString = await rootBundle.loadString('assets/images/bike_marker.svg');

    _personMarkerIcon = await _getSvgImageIcon(personSvgString);
    _bikeMarkerIcon = await _getSvgImageIcon(bikeSvgString);
  }

  Future<BitmapDescriptor> _getSvgImageIcon(String svgString) async {
    final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
    final image = await pictureInfo.picture.toImage(48, 48);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _searchPlaces(String query, bool isPickup) async {
    if (query.isEmpty) {
      setState(() {
        if (isPickup) {
          _pickupPredictions = [];
        } else {
          _dropoffPredictions = [];
        }
      });
      return;
    }

    try {
      final response = await _places.autocomplete(
        query,
        location: _currentPosition != null
            ? Location(lat: _currentPosition!.latitude, lng: _currentPosition!.longitude)
            : null,
        radius: 50000,
      );

      if (response.isOkay) {
        setState(() {
          if (isPickup) {
            _pickupPredictions = response.predictions;
          } else {
            _dropoffPredictions = response.predictions;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching places: $e')),
        );
      }
    }
  }

  Future<void> _getPlaceDetails(String placeId, bool isPickup) async {
    try {
      final details = await _places.getDetailsByPlaceId(placeId);
      if (details.isOkay) {
        final location = details.result.geometry!.location;
        final latLng = LatLng(location.lat, location.lng);
        
        setState(() {
          if (isPickup) {
            _pickupLocation = latLng;
            _pickupController.text = details.result.name ?? '';
            _pickupPredictions = [];
          } else {
            _dropoffLocation = latLng;
            _dropoffController.text = details.result.name ?? '';
            _dropoffPredictions = [];
          }
          _updateMarkers();
          _getRoute();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting place details: $e')),
        );
      }
    }
  }

  Future<void> _getRoute() async {
    if (_pickupLocation == null || _dropoffLocation == null) return;

    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyCPmf03XcowTuWeMD7n43LAV7CeJ5cA3bs',
      PointLatLng(_pickupLocation!.latitude, _pickupLocation!.longitude),
      PointLatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude),
    );

    if (result.points.isNotEmpty) {
      final points = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      // Calculate straight-line distance
      final distanceInMeters = Geolocator.distanceBetween(
        _pickupLocation!.latitude,
        _pickupLocation!.longitude,
        _dropoffLocation!.latitude,
        _dropoffLocation!.longitude,
      );

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 5,
          ),
        );

        // Estimate time based on average speed of 30 km/h
        final distanceInKm = distanceInMeters / 1000;
        _estimatedTime = '${((distanceInKm / 30) * 60).round()} min';
        _estimatedDistance = distanceInKm;
      });
    }
  }

  void _updateMarkers() {
    _markers.clear();
    
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: _bikeMarkerIcon!,
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      );
    }

    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: _pickupController.text),
        ),
      );
    }

    if (_dropoffLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoffLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: _dropoffController.text),
        ),
      );
    }
  }

  Future<void> _loadAvailableRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final source = widget.arguments['source'] as LatLng;
      final destination = widget.arguments['destination'] as LatLng;
      final dateTime = widget.arguments['dateTime'] as DateTime;
      final seats = widget.arguments['seats'] as int;

      // Query rides that match the criteria
      final querySnapshot = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('status', isEqualTo: 'pending')
          .where('seats', isGreaterThanOrEqualTo: seats)
          .orderBy('dateTime')
          .get();

      setState(() {
        _availableRides = querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rides: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _bookRide(String rideId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Update ride status and add booking details
      await FirebaseFirestore.instance.collection('ride_requests').doc(rideId).update({
        'status': 'booked',
        'bookedBy': {
          'userId': user.uid,
          'userName': user.displayName ?? 'Anonymous',
          'userEmail': user.email,
        },
        'bookedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride booked successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking ride: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(
        title: const Text('Available Rides'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableRides.isEmpty
              ? const Center(
                  child: Text(
                    'No rides available matching your criteria',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _availableRides.length,
                  itemBuilder: (context, index) {
                    final ride = _availableRides[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ride['vehicleType'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${ride['price']} per seat',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow('Available Seats', ride['seats'].toString()),
                            _buildDetailRow('Date/Time', _dateFormat.format(ride['dateTime'].toDate())),
                            if (ride['description'] != null && ride['description'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  ride['description'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Posted by: ${ride['userName']}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _bookRide(ride['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Book Ride'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
=======
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
>>>>>>> f822eaa09bbf8b284bad692aaf862a2b4735e9c4
  }
}