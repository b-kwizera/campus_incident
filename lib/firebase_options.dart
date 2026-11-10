// PLACEHOLDER. Replace by running `flutterfire configure` (see SETUP.md).
// That command regenerates this file with your real Firebase project values.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Only Android and iOS are supported.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDQu31uP1xhmwWUrp8hXHnLLVaHLBSnJnk',
    appId: '1:885709311651:android:ced7563db3edd89ec3b916',
    messagingSenderId: '885709311651',
    projectId: 'campus-incident-reporter-78b27',
    storageBucket: 'campus-incident-reporter-78b27.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB3fTgp4ULmjdFuZaFsEJGYyDY8NRIjwgs',
    appId: '1:885709311651:ios:8c63c2da859634dfc3b916',
    messagingSenderId: '885709311651',
    projectId: 'campus-incident-reporter-78b27',
    storageBucket: 'campus-incident-reporter-78b27.firebasestorage.app',
    iosBundleId: 'com.alu.campusIncident',
  );
}
