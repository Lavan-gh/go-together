<<<<<<< HEAD
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
=======
import 'package:firebase_core/firebase_core.dart';
>>>>>>> f822eaa09bbf8b284bad692aaf862a2b4735e9c4

class DefaultFirebaseOptions {
  // Static method to get Firebase options for the current platform
  static FirebaseOptions get currentPlatform {
<<<<<<< HEAD
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDiphufLC5PEVuZhiUH84Pem6Vsn-QBkZ8',
    appId: '1:155146379666:web:69202d19d706727744614b',
    messagingSenderId: '155146379666',
    projectId: 'go-together-780d2',
    authDomain: 'go-together-780d2.firebaseapp.com',
    storageBucket: 'go-together-780d2.firebasestorage.app',
    measurementId: 'G-7VXXV6J99B',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD8vJ7Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8',
    appId: '1:155146379666:android:30f1e46eb3a3b17c44614b',
    messagingSenderId: '155146379666',
    projectId: 'go-together-780d2',
    storageBucket: 'go-together-780d2.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD8vJ7Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8',
    appId: '1:155146379666:ios:275c81b6408e88ff44614b',
    messagingSenderId: '155146379666',
    projectId: 'go-together-780d2',
    storageBucket: 'go-together-780d2.appspot.com',
    iosClientId: 'com.googleusercontent.apps.155146379666-275c81b6408e88ff44614b',
    iosBundleId: 'com.example.goTogether',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD8vJ7Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8',
    appId: '1:155146379666:ios:275c81b6408e88ff44614b',
    messagingSenderId: '155146379666',
    projectId: 'go-together-780d2',
    storageBucket: 'go-together-780d2.appspot.com',
    iosClientId: 'com.googleusercontent.apps.155146379666-275c81b6408e88ff44614b',
    iosBundleId: 'com.example.goTogether',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD8vJ7Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8',
    appId: '1:155146379666:web:99e5a097288ec21c44614b',
    messagingSenderId: '155146379666',
    projectId: 'go-together-780d2',
    authDomain: 'go-together-780d2.firebaseapp.com',
    storageBucket: 'go-together-780d2.appspot.com',
  );
=======
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
>>>>>>> f822eaa09bbf8b284bad692aaf862a2b4735e9c4
}