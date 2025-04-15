import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit a rating for a user
  Future<void> submitRating({
    required String ratedUserId,
    required double rating,
    required String review,
    String? rideId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Check if user has already rated this ride
    if (rideId != null) {
      final existingRating = await getRideRating(rideId);
      if (existingRating != null) {
        throw Exception('You have already rated this ride');
      }
    }

    final ratingData = {
      'raterId': currentUser.uid,
      'ratedUserId': ratedUserId,
      'rating': rating,
      'review': review,
      'rideId': rideId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firestore.collection('ratings').add(ratingData);

    // Update user's average rating
    await _updateUserAverageRating(ratedUserId);
  }

  // Get average rating for a user
  Stream<double> getUserAverageRating(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => (snapshot.data()?['averageRating'] as num?)?.toDouble() ?? 0.0);
  }

  // Get all ratings for a user
  Stream<List<Map<String, dynamic>>> getUserRatings(String userId) {
    return _firestore
        .collection('ratings')
        .where('ratedUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'rating': data['rating'],
          'review': data['review'],
          'timestamp': data['timestamp'],
          'raterId': data['raterId'],
          'rideId': data['rideId'],
        };
      }).toList();
    });
  }

  // Get rating for a specific ride
  Future<Map<String, dynamic>?> getRideRating(String rideId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final querySnapshot = await _firestore
        .collection('ratings')
        .where('rideId', isEqualTo: rideId)
        .where('raterId', isEqualTo: currentUser.uid)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    final doc = querySnapshot.docs.first;
    final data = doc.data();
    return {
      'id': doc.id,
      'rating': data['rating'],
      'review': data['review'],
      'timestamp': data['timestamp'],
    };
  }

  // Delete a rating
  Future<void> deleteRating(String ratingId) async {
    final ratingDoc = await _firestore.collection('ratings').doc(ratingId).get();
    if (!ratingDoc.exists) throw Exception('Rating not found');

    final ratedUserId = ratingDoc.data()?['ratedUserId'] as String;
    await _firestore.collection('ratings').doc(ratingId).delete();
    await _updateUserAverageRating(ratedUserId);
  }

  // Update user's average rating
  Future<void> _updateUserAverageRating(String userId) async {
    final ratingsSnapshot = await _firestore
        .collection('ratings')
        .where('ratedUserId', isEqualTo: userId)
        .get();

    if (ratingsSnapshot.docs.isEmpty) return;

    final ratings = ratingsSnapshot.docs
        .map((doc) => (doc.data()['rating'] as num).toDouble())
        .toList();

    final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

    await _firestore.collection('users').doc(userId).update({
      'averageRating': averageRating,
      'totalRatings': ratings.length,
    });
  }

  // Get user's rating statistics
  Future<Map<String, dynamic>> getUserRatingStats(String userId) async {
    final ratingsSnapshot = await _firestore
        .collection('ratings')
        .where('ratedUserId', isEqualTo: userId)
        .get();

    if (ratingsSnapshot.docs.isEmpty) {
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'ratingDistribution': [0, 0, 0, 0, 0],
      };
    }

    final ratings = ratingsSnapshot.docs
        .map((doc) => (doc.data()['rating'] as num).toInt())
        .toList();

    final ratingDistribution = List<int>.filled(5, 0);
    for (final rating in ratings) {
      ratingDistribution[rating - 1]++;
    }

    return {
      'averageRating': ratings.reduce((a, b) => a + b) / ratings.length,
      'totalRatings': ratings.length,
      'ratingDistribution': ratingDistribution,
    };
  }
} 