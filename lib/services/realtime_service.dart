import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RealtimeService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize real-time services
  Future<void> initialize() async {
    // Request notification permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      // Store token in database
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _database.ref('users/${user.uid}/fcmToken').set(token);
      }
    }

    // Handle incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle background messages when app is opened
      print('Message opened from background!');
      print('Message data: ${message.data}');
    });
  }

  // Start tracking a ride
  Future<void> startRideTracking(String rideId, String userId) async {
    // Create a reference to the ride location in the database
    final rideRef = _database.ref('rides/$rideId/location');

    // Set up location updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) async {
      // Update ride location in database
      await rideRef.set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': ServerValue.timestamp,
      });
    });
  }

  // Stop tracking a ride
  Future<void> stopRideTracking(String rideId) async {
    final rideRef = _database.ref('rides/$rideId/location');
    await rideRef.remove();
  }

  // Get real-time ride location
  Stream<LatLng> getRideLocation(String rideId) {
    return _database.ref('rides/$rideId/location').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return LatLng(
        data['latitude'] as double,
        data['longitude'] as double,
      );
    });
  }

  // Send a notification to a user
  Future<void> sendNotification(String userId, String title, String body) async {
    // Get the user's FCM token
    final tokenSnapshot = await _database.ref('users/$userId/fcmToken').get();
    final String? token = tokenSnapshot.value as String?;

    if (token != null) {
      // Send notification using Firebase Cloud Messaging
      await _messaging.sendMessage(
        to: token,
        data: {
          'title': title,
          'body': body,
        },
      );
    }
  }

  // Subscribe to ride updates
  Stream<Map<String, dynamic>> subscribeToRide(String rideId) {
    return _database.ref('rides/$rideId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return Map<String, dynamic>.from(data);
    });
  }
} 