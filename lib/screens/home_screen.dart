import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_together/theme/app_theme.dart';
import 'book_ride_screen.dart';
import 'request_ride_screen.dart';
import 'profile_screen.dart';
import 'co2_tracker_screen.dart';
import 'history_screen.dart';
import 'sos_screen.dart';
import 'reviews_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;
  double _co2Saved = 0.0;
  double _rating = 4.5;
  int _totalRides = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      
      if (userDoc.exists) {
        setState(() {
          _co2Saved = userDoc.data()?['co2Saved'] ?? 0.0;
          _rating = userDoc.data()?['rating'] ?? 4.5;
        });
      }

      final ridesSnapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('userId', isEqualTo: user!.uid)
          .get();
      
      setState(() {
        _totalRides = ridesSnapshot.docs.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              AppTheme.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              AppTheme.appSlogan,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(),
          ProfileScreen(),
          CO2TrackerScreen(),
          HistoryScreen(),
          ReviewsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.greyColor,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: 'CO2 Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Reviews',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SOSScreen()),
        ),
        child: Icon(Icons.emergency),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          SizedBox(height: 24),
          _buildStatsCard(),
          SizedBox(height: 24),
          _buildActionButtons(),
          SizedBox(height: 24),
          _buildRecentRides(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 20,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ready to save money and reduce your carbon footprint?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              Icons.eco,
              'CO2 Saved',
              '${_co2Saved.toStringAsFixed(1)} kg',
              AppTheme.accentColor,
            ),
            _buildStatItem(
              Icons.star,
              'Rating',
              _rating.toStringAsFixed(1),
              Colors.amber,
            ),
            _buildStatItem(
              Icons.directions_car,
              'Rides',
              _totalRides.toString(),
              AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookRideScreen()),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car),
              SizedBox(width: 8),
              Text('Book a Ride'),
            ],
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RequestRideScreen()),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_location),
              SizedBox(width: 8),
              Text('Offer a Ride'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Rides',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rides')
              .where('userId', isEqualTo: user?.uid)
              .orderBy('timestamp', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 64,
                      color: AppTheme.greyColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No recent rides',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final ride = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ride['type'] == 'booked' 
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        ride['type'] == 'booked' 
                            ? Icons.directions_car 
                            : Icons.add_location,
                        color: ride['type'] == 'booked' ? Colors.blue : Colors.green,
                      ),
                    ),
                    title: Text('${ride['source']} → ${ride['destination']}'),
                    subtitle: Text(
                      ride['date'],
                      style: Theme.of(context).textTheme.bodyMedium,
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
            );
          },
        ),
      ],
    );
  }
} 