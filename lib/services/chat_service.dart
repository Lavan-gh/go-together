import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send a message in a ride chat
  Future<void> sendMessage(String rideId, String message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messageRef = _database.ref('rides/$rideId/chat').push();
    await messageRef.set({
      'senderId': user.uid,
      'senderName': user.displayName ?? 'Anonymous',
      'message': message,
      'timestamp': ServerValue.timestamp,
    });
  }

  // Get messages for a ride
  Stream<List<Map<String, dynamic>>> getMessages(String rideId) {
    return _database.ref('rides/$rideId/chat')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.entries.map((entry) {
        final message = Map<String, dynamic>.from(entry.value as Map);
        message['id'] = entry.key;
        return message;
      }).toList()
        ..sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String rideId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _database.ref('rides/$rideId/chat').once().then((snapshot) {
      final Map<dynamic, dynamic>? data = snapshot.value as Map?;
      if (data == null) return;

      data.forEach((key, value) {
        if (value['senderId'] != user.uid && value['read'] != true) {
          _database.ref('rides/$rideId/chat/$key/read').set(true);
        }
      });
    });
  }

  // Get unread message count for a ride
  Stream<int> getUnreadMessageCount(String rideId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _database.ref('rides/$rideId/chat')
        .onValue
        .map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return 0;

      return data.values.where((message) {
        return message['senderId'] != user.uid && message['read'] != true;
      }).length;
    });
  }
} 