import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:google_maps_webservice/places.dart';
import 'package:google_maps_webservice/geocoding.dart' as geocoding;
import 'package:go_together/profile.dart';
import 'package:go_together/sos.dart';
import 'package:go_together/co2_tracker.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
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
  String _selectedVehicleType = 'Car';
  GoogleMapController? _mapController;
  late GoogleMapsPlaces _places;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  final _geocoding = geocoding.GoogleMapsGeocoding(apiKey: 'AIzaSyCPmf03XcowTuWeMD7n43LAV7CeJ5cA3bs');
  List<Prediction> _sourcePredictions = [];
  List<Prediction> _destinationPredictions = [];
  bool _isSourceDropdownOpen = false;
  bool _isDestinationDropdownOpen = false;
  LatLng? _sourceLocation;
  LatLng? _destinationLocation;
  String _currentAddress = '';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _sessionToken = '';

  // Initialize state
  @override
  void initState() {
    super.initState();
    _places = GoogleMapsPlaces(apiKey: 'YOUR_API_KEY');
    _getCurrentLocation();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationController.forward();
  }

  // Dispose controllers
  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _mapController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

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

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _currentCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        );
        _updateMarkers();
      });

      // Get address from coordinates
      await _getAddressFromCoordinates(position.latitude, position.longitude);

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(_currentCameraPosition),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      final response = await _geocoding.searchByLocation(
        geocoding.Location(lat: lat, lng: lng),
      );

      if (response.isOkay) {
        final result = response.results.first;
        String formattedAddress = result.formattedAddress ?? '';
        
        // Extract address components
        String village = '';
        String mandal = '';
        String district = '';
        String pincode = '';
        
        for (var component in result.addressComponents) {
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
          _currentAddress = formattedAddress;
          _sourceController.text = detailedAddress;
          _sourceLocation = LatLng(lat, lng);
          _updateMarkers();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting address: $e')),
        );
      }
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();
      
      // Add current location marker
      if (_currentPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            infoWindow: const InfoWindow(title: 'Current Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }

      // Add source location marker
      if (_sourceLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('source_location'),
            position: _sourceLocation!,
            infoWindow: InfoWindow(title: _sourceController.text),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            draggable: true,
            onDragEnd: (newPosition) {
              _getAddressFromCoordinates(newPosition.latitude, newPosition.longitude);
            },
          ),
        );
      }

      // Add destination location marker
      if (_destinationLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('destination_location'),
            position: _destinationLocation!,
            infoWindow: InfoWindow(title: _destinationController.text),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            draggable: true,
            onDragEnd: (newPosition) {
              _getAddressFromCoordinates(newPosition.latitude, newPosition.longitude);
            },
          ),
        );
      }
    });
  }

  Future<void> _searchPlaces(String query, bool isSource) async {
    if (query.isEmpty) {
      setState(() {
        if (isSource) {
          _sourcePredictions = [];
        } else {
          _destinationPredictions = [];
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
        sessionToken: _sessionToken,
      );

      if (response.isOkay) {
        setState(() {
          if (isSource) {
            _sourcePredictions = response.predictions;
          } else {
            _destinationPredictions = response.predictions;
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
              onPressed: () => _searchPlaces(query, isSource),
            ),
          ),
        );
      }
    }
  }

  Future<void> _getPlaceDetails(String placeId, bool isSource) async {
    try {
      final details = await _places.getDetailsByPlaceId(
        placeId,
        sessionToken: _sessionToken,
      );
      
      if (details.isOkay) {
        final location = details.result.geometry!.location;
        final latLng = LatLng(location.lat, location.lng);
        final formattedAddress = details.result.formattedAddress ?? '';
        
        setState(() {
          if (isSource) {
            _sourceLocation = latLng;
            _sourceController.text = formattedAddress;
            _sourcePredictions = [];
            _isSourceDropdownOpen = false;
          } else {
            _destinationLocation = latLng;
            _destinationController.text = formattedAddress;
            _destinationPredictions = [];
            _isDestinationDropdownOpen = false;
          }
          _updateMarkers();
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(latLng),
          );
        }
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
              onPressed: () => _getPlaceDetails(placeId, isSource),
            ),
          ),
        );
      }
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
    if (_sourceLocation == null || _destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both source and destination locations')),
      );
      return;
    }

    Navigator.pushNamed(context, '/request_ride', arguments: {
      'source': _sourceLocation,
      'destination': _destinationLocation,
      'seats': _selectedSeats,
      'vehicleType': _selectedVehicleType,
      'dateTime': _selectedDateTime,
    });
  }

  void _bookRide() {
    if (_sourceLocation == null || _destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both source and destination locations')),
      );
      return;
    }

    Navigator.pushNamed(context, '/book_ride', arguments: {
      'source': _sourceLocation,
      'destination': _destinationLocation,
      'seats': _selectedSeats,
      'vehicleType': _selectedVehicleType,
      'dateTime': _selectedDateTime,
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Together'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.teal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.displayName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.car_rental),
              title: const Text('My Rides'),
              onTap: () {
                // TODO: Implement my rides
              },
            ),
            ListTile(
              leading: const Icon(Icons.eco),
              title: const Text('CO2 Tracker'),
              onTap: () {
                Navigator.pushNamed(context, '/co2_tracker');
              },
            ),
            ListTile(
              leading: const Icon(Icons.emergency),
              title: const Text('SOS'),
              onTap: () {
                Navigator.pushNamed(context, '/sos');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _currentCameraPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: true,
            zoomControlsEnabled: true,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          SafeArea(
            child: Column(
              children: [
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.teal),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: const Text('Select Source'),
                                    value: _sourceController.text.isEmpty
                                        ? null
                                        : _sourceController.text,
                                    items: [
                                      DropdownMenuItem(
                                        value: 'current_location',
                                        child: Row(
                                          children: const [
                                            Icon(Icons.my_location),
                                            SizedBox(width: 8),
                                            Text('Current Location'),
                                          ],
                                        ),
                                      ),
                                      ..._sourcePredictions.map((prediction) {
                                        return DropdownMenuItem(
                                          value: prediction.description,
                                          child: Text(prediction.description!),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) {
                                      if (value == 'current_location') {
                                        _getCurrentLocation();
                                      } else {
                                        final prediction = _sourcePredictions
                                            .firstWhere((p) =>
                                                p.description == value);
                                        _getPlaceDetails(
                                            prediction.placeId!, true);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: const Text('Select Destination'),
                                    value: _destinationController.text.isEmpty
                                        ? null
                                        : _destinationController.text,
                                    items: _destinationPredictions
                                        .map((prediction) {
                                          return DropdownMenuItem(
                                            value: prediction.description,
                                            child: Text(prediction.description!),
                                          );
                                        })
                                        .toList(),
                                    onChanged: (value) {
                                      final prediction = _destinationPredictions
                                          .firstWhere((p) =>
                                              p.description == value);
                                      _getPlaceDetails(prediction.placeId!, false);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(
                            Icons.person,
                            'Profile',
                            () => Navigator.pushNamed(context, '/profile'),
                          ),
                          _buildActionButton(
                            Icons.warning,
                            'SOS',
                            () => Navigator.pushNamed(context, '/sos'),
                          ),
                          _buildActionButton(
                            Icons.eco,
                            'CO2 Tracker',
                            () => Navigator.pushNamed(context, '/co2_tracker'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: lottie.Lottie.asset(
                  'assets/animations/loading.json',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.teal),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}