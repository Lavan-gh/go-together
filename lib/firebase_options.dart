import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  // Static method to get Firebase options for the current platform
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      // API key for Firebase
      apiKey: 'AIzaSyC7lU0-1XIfKFPW2RsIpqxglDnrjU0XnuU',
      // App ID for Android
      appId: '1:155146379666:android:c5f1fe721e6ca9b244614b',
      // Messaging sender ID
      messagingSenderId: '155146379666',
      // Project ID
      projectId: 'go-together-780d2',
      // Auth domain
      authDomain: 'go-together-780d2.firebaseapp.com',
      // Database URL
      databaseURL: 'https://go-together-780d2-default-rtdb.firebaseio.com',
      // Storage bucket
      storageBucket: 'go-together-780d2.appspot.com',
    );
  }
}