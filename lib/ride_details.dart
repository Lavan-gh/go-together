import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class RideDetailsPage extends StatefulWidget {
  final String rideId;
  
  const RideDetailsPage({super.key, required this.rideId});

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  Map<String, dynamic>? _rideData;
  Position? _currentPosition;
  Stream<DocumentSnapshot>? _rideStream;
  bool _isDriver = false;
  bool _isPassenger = false;

  @override
  void initState() {
    super.initState();
    _setupRideStream();
    _checkUserRole();
    _getCurrentLocation();
  }

  void _setupRideStream() {
    _rideStream = FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .snapshots();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final rideDoc = await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .get();
      
      if (rideDoc.exists) {
        final data = rideDoc.data() as Map<String, dynamic>;
        setState(() {
          _isDriver = data['driverId'] == user.uid;
          _isPassenger = (data['passengers'] as List<dynamic>?)
              ?.contains(user.uid) ?? false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _updateRoute(Map<String, dynamic> rideData) async {
    if (rideData['pickupLocation'] == null || rideData['dropoffLocation'] == null) {
      return;
    }

    final pickupLocation = rideData['pickupLocation'] as GeoPoint;
    final dropoffLocation = rideData['dropoffLocation'] as GeoPoint;
    
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyCPmf03XcowTuWeMD7n43LAV7CeJ5cA3bs',
      PointLatLng(pickupLocation.latitude, pickupLocation.longitude),
      PointLatLng(dropoffLocation.latitude, dropoffLocation.longitude),
    );

    if (result.points.isNotEmpty) {
      final points = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(pickupLocation.latitude, pickupLocation.longitude),
            infoWindow: const InfoWindow(title: 'Pickup Location'),
          ),
        );
        _markers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: LatLng(dropoffLocation.latitude, dropoffLocation.longitude),
            infoWindow: const InfoWindow(title: 'Dropoff Location'),
          ),
        );

        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 5,
          ),
        );

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  points.map((p) => p.latitude).reduce(min),
                  points.map((p) => p.longitude).reduce(min),
                ),
                northeast: LatLng(
                  points.map((p) => p.latitude).reduce(max),
                  points.map((p) => p.longitude).reduce(max),
                ),
              ),
              50.0,
            ),
          );
        }
      });
    }
  }

  void _shareRideDetails() {
    if (_rideData == null) return;

    final pickupLocation = _rideData!['pickupLocationName'] as String;
    final dropoffLocation = _rideData!['dropoffLocationName'] as String;
    final date = (_rideData!['date'] as Timestamp).toDate();
    final time = _rideData!['time'] as String;
    final price = _rideData!['pricePerSeat'] as num;

    final message = '''
Join me on Go Together!
🚗 Ride from $pickupLocation to $dropoffLocation
📅 ${DateFormat('MMM d, yyyy').format(date)} at $time
💰 \$${price.toStringAsFixed(2)} per seat
🔗 Ride ID: ${widget.rideId}
''';

    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareRideDetails,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _rideStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          _rideData = data;
          _updateRoute(data);

          return Column(
            children: [
              Expanded(
                flex: 1,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : const LatLng(0, 0),
                    zoom: 12,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (controller) => _mapController = controller,
                ),
              ),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From: ${data['pickupLocationName']}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'To: ${data['dropoffLocationName']}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date: ${DateFormat('MMM d, yyyy').format((data['date'] as Timestamp).toDate())}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            'Time: ${data['time']}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Price per seat: \$${(data['pricePerSeat'] as num).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            'Available seats: ${data['availableSeats']}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (!_isDriver && !_isPassenger && data['availableSeats'] > 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _bookRide(data),
                            child: const Text('Book Ride'),
                          ),
                        ),
                      if (_isPassenger)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _cancelBooking(data),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Cancel Booking'),
                          ),
                        ),
                      if (_isDriver)
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _startRide(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Start Ride'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _cancelRide(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Cancel Ride'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _bookRide(Map<String, dynamic> rideData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to book a ride')),
        );
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final rideRef = FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.rideId);
        
        final rideDoc = await transaction.get(rideRef);
        final currentData = rideDoc.data() as Map<String, dynamic>;
        
        if (currentData['availableSeats'] <= 0) {
          throw Exception('No seats available');
        }

        transaction.update(rideRef, {
          'passengers': FieldValue.arrayUnion([user.uid]),
          'availableSeats': FieldValue.increment(-1),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride booked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking ride: $e')),
        );
      }
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> rideData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .update({
        'passengers': FieldValue.arrayRemove([user.uid]),
        'availableSeats': FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling booking: $e')),
        );
      }
    }
  }

  Future<void> _startRide() async {
    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .update({
        'status': 'in_progress',
        'startTime': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride started successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting ride: $e')),
        );
      }
    }
  }

  Future<void> _cancelRide() async {
    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .update({
        'status': 'cancelled',
        'cancelTime': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride cancelled successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling ride: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
} 