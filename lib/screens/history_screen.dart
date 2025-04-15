import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _rides = [];

  @override
  void initState() {
    super.initState();
    _loadRideHistory();
  }

  Future<void> _loadRideHistory() async {
    if (user == null) return;

    try {
      final ridesSnapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _rides = ridesSnapshot.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading ride history: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ride History'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _rides.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No ride history yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _rides.length,
                  itemBuilder: (context, index) {
                    final ride = _rides[index];
                    final date = (ride['timestamp'] as Timestamp).toDate();
                    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
                    final formattedTime = DateFormat('hh:mm a').format(date);

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          ride['type'] == 'booked' ? Icons.directions_car : Icons.add_location,
                          color: ride['type'] == 'booked' ? Colors.blue : Colors.green,
                        ),
                        title: Text(
                          '${ride['type'] == 'booked' ? 'Booked' : 'Offered'} Ride',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From: ${ride['source']}'),
                            Text('To: ${ride['destination']}'),
                            Text('$formattedDate at $formattedTime'),
                            if (ride['status'] != null)
                              Text(
                                'Status: ${ride['status']}',
                                style: TextStyle(
                                  color: ride['status'] == 'completed'
                                      ? Colors.green
                                      : ride['status'] == 'cancelled'
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.star),
                          onPressed: () {
                            // TODO: Navigate to rating screen
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 