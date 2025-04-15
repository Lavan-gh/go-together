import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestRidePage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const RequestRidePage({Key? key, required this.arguments}) : super(key: key);

  @override
  State<RequestRidePage> createState() => _RequestRidePageState();
}

class _RequestRidePageState extends State<RequestRidePage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  bool _isLoading = true;
  String _selectedVehicleType = 'Car';
  int _availableSeats = 1;
  DateTime _selectedDateTime = DateTime.now();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');
  double _pricePerSeat = 0.0;
  bool _isPriceSet = false;
  List<Prediction> _pickupPredictions = [];
  List<Prediction> _dropoffPredictions = [];
  final _places = GoogleMapsPlaces(apiKey: 'YOUR_GOOGLE_MAPS_API_KEY');
  BitmapDescriptor? _personMarkerIcon;
  BitmapDescriptor? _bikeMarkerIcon;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String? _estimatedTime;
  double? _estimatedDistance;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadMarkerIcons();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
      return;
    }

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

    try {
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
        types: ['address', 'establishment', 'geocode', 'point_of_interest'],
        components: [Component('country', 'in')], // Restrict to India
      );

      if (response.isOkay) {
        setState(() {
          if (isPickup) {
            _pickupPredictions = response.predictions;
          } else {
            _dropoffPredictions = response.predictions;
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching places: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _searchPlaces(query, isPickup),
            ),
          ),
        );
      }
    }
  }

  Future<void> _getPlaceDetails(String placeId, bool isPickup) async {
    try {
      final details = await _places.getDetailsByPlaceId(
        placeId,
      );
      
      if (details.isOkay) {
        final location = details.result.geometry!.location;
        final latLng = LatLng(location.lat, location.lng);
        
        // Extract address components
        String village = '';
        String mandal = '';
        String district = '';
        String pincode = '';
        
        for (var component in details.result.addressComponents) {
          if (component.types.contains('locality')) {
            village = component.longName;
          } else if (component.types.contains('administrative_area_level_2')) {
            mandal = component.longName;
          } else if (component.types.contains('administrative_area_level_1')) {
            district = component.longName;
          } else if (component.types.contains('postal_code')) {
            pincode = component.longName;
          }
        }

        // Format the address with all components
        String detailedAddress = [
          village,
          mandal,
          district,
          pincode,
        ].where((part) => part.isNotEmpty).join(', ');
        
        setState(() {
          if (isPickup) {
            _pickupLocation = latLng;
            _pickupController.text = detailedAddress;
            _pickupPredictions = [];
          } else {
            _dropoffLocation = latLng;
            _dropoffController.text = detailedAddress;
            _dropoffPredictions = [];
          }
          _updateMarkers();
          _getRoute();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${details.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting place details: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _getPlaceDetails(placeId, isPickup),
            ),
          ),
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

  Future<void> _submitRideRequest() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a price')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final rideRequest = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userEmail': user.email,
        'source': {
          'latitude': (widget.arguments['source'] as LatLng).latitude,
          'longitude': (widget.arguments['source'] as LatLng).longitude,
        },
        'destination': {
          'latitude': (widget.arguments['destination'] as LatLng).latitude,
          'longitude': (widget.arguments['destination'] as LatLng).longitude,
        },
        'seats': widget.arguments['seats'],
        'vehicleType': widget.arguments['vehicleType'],
        'dateTime': widget.arguments['dateTime'],
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('ride_requests').add(rideRequest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride request submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting ride request: $e')),
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
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final source = widget.arguments['source'] as LatLng;
    final destination = widget.arguments['destination'] as LatLng;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Ride'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride Details Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ride Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Vehicle Type', widget.arguments['vehicleType']),
                    _buildDetailRow('Seats', widget.arguments['seats'].toString()),
                    _buildDetailRow('Date/Time', dateFormat.format(widget.arguments['dateTime'])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Price Input
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price per Seat (₹)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            // Description Input
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Additional Details (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRideRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Ride Request',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 