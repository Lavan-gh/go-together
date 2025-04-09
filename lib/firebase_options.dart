import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';  // Importing the generated Firebase config file.

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyC7lU0-1XIfKFPW2RsIpqxglDnrjU0XnuU',
      appId: '1:155146379666:android:c5f1fe721e6ca9b244614b',
      messagingSenderId: '155146379666',
      projectId: 'go-together-780d2',
      authDomain: 'go-together-780d2.firebaseapp.com',
      databaseURL: 'https://go-together-780d2-default-rtdb.firebaseio.com',
      storageBucket: 'go-together-780d2.appspot.com',
    );
  }
}
