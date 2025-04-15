// @dart=2.19

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
<<<<<<< HEAD
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/co2_tracker_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/book_ride_screen.dart';
import 'screens/request_ride_screen.dart';
import 'firebase_options.dart';
=======
import 'firebase_options.dart'; // Ensure this file is correctly configured

import 'login.dart';
import 'register.dart';
import 'home.dart';
import 'profile.dart';
import 'edit_profile.dart';
import 'sos.dart';
import 'give_ride.dart';
import 'book_ride.dart';
import 'co2_tracker.dart';
>>>>>>> f822eaa09bbf8b284bad692aaf862a2b4735e9c4

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go Together',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/book_ride': (context) => BookRideScreen(),
        '/request_ride': (context) => RequestRideScreen(),
        '/sos': (context) => SOSScreen(),
        '/co2_tracker': (context) => CO2TrackerScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasData) {
          return HomeScreen();
        }
        
        return LoginScreen();
      },
    );
  }
}