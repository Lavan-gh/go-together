import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PaymentService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Add money to wallet
  Future<void> addToWallet(double amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final result = await _functions.httpsCallable('addToWallet').call({
        'amount': amount,
        'userId': user.uid,
      });

      if (result.data['success']) {
        await _database.ref('users/${user.uid}/wallet').set(
          ServerValue.increment(amount),
        );
      }
    } catch (e) {
      throw Exception('Failed to add money to wallet: $e');
    }
  }

  // Get wallet balance
  Future<double> getWalletBalance() async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    final snapshot = await _database.ref('users/${user.uid}/wallet').get();
    return (snapshot.value as num?)?.toDouble() ?? 0.0;
  }

  // Process ride payment
  Future<void> processRidePayment(String rideId, double amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final result = await _functions.httpsCallable('processRidePayment').call({
        'rideId': rideId,
        'amount': amount,
        'userId': user.uid,
      });

      if (result.data['success']) {
        // Update wallet balance
        await _database.ref('users/${user.uid}/wallet').set(
          ServerValue.increment(-amount),
        );

        // Record transaction
        await _database.ref('transactions').push().set({
          'userId': user.uid,
          'rideId': rideId,
          'amount': amount,
          'type': 'ride_payment',
          'timestamp': ServerValue.timestamp,
          'status': 'completed',
        });
      }
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  // Get transaction history
  Stream<List<Map<String, dynamic>>> getTransactionHistory() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _database.ref('transactions')
        .orderByChild('userId')
        .equalTo(user.uid)
        .onValue
        .map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.entries.map((entry) {
        final transaction = Map<String, dynamic>.from(entry.value as Map);
        transaction['id'] = entry.key;
        return transaction;
      }).toList()
        ..sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
    });
  }

  // Request refund
  Future<void> requestRefund(String transactionId, String reason) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final result = await _functions.httpsCallable('requestRefund').call({
        'transactionId': transactionId,
        'userId': user.uid,
        'reason': reason,
      });

      if (result.data['success']) {
        await _database.ref('transactions/$transactionId/status').set('refund_requested');
      }
    } catch (e) {
      throw Exception('Failed to request refund: $e');
    }
  }
} 