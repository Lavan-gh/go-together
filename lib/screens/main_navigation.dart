import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_ride_screen.dart';
import 'request_ride_screen.dart';
import 'profile_screen.dart';
import 'co2_tracker_screen.dart';
import 'history_screen.dart';
import 'security_screen.dart';
import 'sos_screen.dart';
import 'rating_screen.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  final List<Widget> _screens = [
    BookRideScreen(),
    RequestRideScreen(),
    HistoryScreen(),
    ProfileScreen(),
    CO2TrackerScreen(),
    SecurityScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Book Ride',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_location),
            label: 'Offer Ride',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
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
            icon: Icon(Icons.security),
            label: 'Security',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SOSScreen()),
          );
        },
        child: Icon(Icons.emergency),
        backgroundColor: Colors.red,
      ),
    );
  }
} 