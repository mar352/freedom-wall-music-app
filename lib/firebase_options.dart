// Firebase configuration for Freedom Wall App
// Project ID: freedomwall-153ed
// Real Firebase configuration loaded from google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ✅ Real Firebase configuration values from your project
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDUAhkRqrAndFdb4Qs-YKfQLFkgyPl7oSE',
    appId: '1:220750437582:web:497725868cee1f8aff849f',
    messagingSenderId: '220750437582',
    projectId: 'freedomwall-153ed',
    authDomain: 'freedomwall-153ed.firebaseapp.com',
    storageBucket: 'freedomwall-153ed.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUAhkRqrAndFdb4Qs-YKfQLFkgyPl7oSE',
    appId: '1:220750437582:android:497725868cee1f8aff849f',
    messagingSenderId: '220750437582',
    projectId: 'freedomwall-153ed',
    storageBucket: 'freedomwall-153ed.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUAhkRqrAndFdb4Qs-YKfQLFkgyPl7oSE',
    appId: '1:220750437582:ios:497725868cee1f8aff849f',
    messagingSenderId: '220750437582',
    projectId: 'freedomwall-153ed',
    storageBucket: 'freedomwall-153ed.firebasestorage.app',
    iosClientId:
        '220750437582-497725868cee1f8aff849f.apps.googleusercontent.com',
    iosBundleId: 'com.example.freedomapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDUAhkRqrAndFdb4Qs-YKfQLFkgyPl7oSE',
    appId: '1:220750437582:macos:497725868cee1f8aff849f',
    messagingSenderId: '220750437582',
    projectId: 'freedomwall-153ed',
    storageBucket: 'freedomwall-153ed.firebasestorage.app',
    iosClientId:
        '220750437582-497725868cee1f8aff849f.apps.googleusercontent.com',
    iosBundleId: 'com.example.freedomapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDUAhkRqrAndFdb4Qs-YKfQLFkgyPl7oSE',
    appId: '1:220750437582:windows:497725868cee1f8aff849f',
    messagingSenderId: '220750437582',
    projectId: 'freedomwall-153ed',
    storageBucket: 'freedomwall-153ed.firebasestorage.app',
  );
}
