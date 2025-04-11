// @dart=2.19

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoTogether App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/login' : '/home',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/edit_profile': (context) => const EditProfilePage(),
        '/sos': (context) => const SOSPage(),
        '/give_ride': (context) => const GiveRidePage(),
        '/book_ride': (context) => const BookRidePage(),
        '/co2_tracker': (context) => const CO2TrackerPage(),
      },
    );
  }
}