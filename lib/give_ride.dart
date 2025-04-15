import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class GiveRidePage extends StatefulWidget {
  const GiveRidePage({super.key});

  @override
  State<GiveRidePage> createState() => _GiveRidePageState();
}

class _GiveRidePageState extends State<GiveRidePage> {
  late GoogleMapController _mapController;
  LatLng _currentLocation = const LatLng(37.7749, -122.4194);
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  bool _isLoading = true;
  int _availableSeats = 1;
  double _farePerSeat = 0.0;
  DateTime _departureTime = DateTime.now();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');
  String _selectedVehicleType = 'Car';
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _fareController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _fareController.dispose();
    super.dispose();
  }

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

  Future<void> _selectDepartureTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _departureTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_departureTime),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _departureTime = DateTime(
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

  void _onMapTapped(LatLng position) {
    if (_pickupLocation == null) {
      setState(() {
        _pickupLocation = position;
        _pickupController.text = '${position.latitude}, ${position.longitude}';
      });
    } else if (_dropoffLocation == null) {
      setState(() {
        _dropoffLocation = position;
        _dropoffController.text = '${position.latitude}, ${position.longitude}';
      });
    }
  }

  void _clearLocations() {
    setState(() {
      _pickupLocation = null;
      _dropoffLocation = null;
      _pickupController.clear();
      _dropoffController.clear();
    });
  }

  void _submitRide() {
    if (_pickupLocation == null || _dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both pickup and drop-off locations.')),
      );
      return;
    }

    if (_farePerSeat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a valid fare per seat.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle Type: $_selectedVehicleType'),
            Text('Available Seats: $_availableSeats'),
            Text('Fare per Seat: \$${_farePerSeat.toStringAsFixed(2)}'),
            Text('Departure Time: ${_dateFormat.format(_departureTime)}'),
            const SizedBox(height: 16),
            const Text('Pickup Location:'),
            Text(_pickupController.text),
            const SizedBox(height: 8),
            const Text('Drop-off Location:'),
            Text(_dropoffController.text),
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
                const SnackBar(content: Text('Ride submitted successfully!')),
              );
              // TODO: Implement ride submission to backend
            },
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
        title: const Text('Give a Ride'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map
                Expanded(
                  child: Stack(
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
                          if (_pickupLocation != null)
                            Marker(
                              markerId: const MarkerId('pickup'),
                              position: _pickupLocation!,
                              infoWindow: const InfoWindow(title: 'Pickup'),
                            ),
                          if (_dropoffLocation != null)
                            Marker(
                              markerId: const MarkerId('dropoff'),
                              position: _dropoffLocation!,
                              infoWindow: const InfoWindow(title: 'Drop-off'),
                            ),
                        },
                        onTap: _onMapTapped,
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildVehicleTypeButton('Car', Icons.directions_car),
                                    _buildVehicleTypeButton('Bike', Icons.motorcycle),
                                    _buildVehicleTypeButton('Rider', Icons.person),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Seats:'),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            setState(() {
                                              if (_availableSeats > 1) _availableSeats--;
                                            });
                                          },
                                        ),
                                        Text('$_availableSeats'),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            setState(() {
                                              _availableSeats++;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom Sheet
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _pickupController,
                        decoration: const InputDecoration(
                          labelText: 'Pickup Location',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _dropoffController,
                        decoration: const InputDecoration(
                          labelText: 'Drop-off Location',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Departure Time:'),
                          TextButton(
                            onPressed: _selectDepartureTime,
                            child: Text(
                              _dateFormat.format(_departureTime),
                              style: const TextStyle(color: Colors.teal),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fareController,
                        decoration: const InputDecoration(
                          labelText: 'Fare per Seat (\$)',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _farePerSeat = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _clearLocations,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitRide,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Submit Ride',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildVehicleTypeButton(String type, IconData icon) {
    final isSelected = _selectedVehicleType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.teal : Colors.grey,
            ),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.teal : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}