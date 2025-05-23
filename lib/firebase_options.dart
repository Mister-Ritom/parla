// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCQS1uDvV_gkwp9a8jwD3vJ64GchMyHZF4',
    appId: '1:1022682226044:web:1a96d45d4d62e08e2d18f9',
    messagingSenderId: '1022682226044',
    projectId: 'parla-debug',
    authDomain: 'parla-debug.firebaseapp.com',
    storageBucket: 'parla-debug.firebasestorage.app',
    measurementId: 'G-C9JJNWCLBN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCpLimomqqyhUV-dGnSbeOP4LREIjcfdec',
    appId: '1:1022682226044:android:74f5a8ababb30f822d18f9',
    messagingSenderId: '1022682226044',
    projectId: 'parla-debug',
    storageBucket: 'parla-debug.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC2ypYIBXV_oXKmsiOShYqJL5d-VwyrsbA',
    appId: '1:1022682226044:ios:7ac4cb9c362158dd2d18f9',
    messagingSenderId: '1022682226044',
    projectId: 'parla-debug',
    storageBucket: 'parla-debug.firebasestorage.app',
    iosBundleId: 'site.ritom.parla',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC2ypYIBXV_oXKmsiOShYqJL5d-VwyrsbA',
    appId: '1:1022682226044:ios:7ac4cb9c362158dd2d18f9',
    messagingSenderId: '1022682226044',
    projectId: 'parla-debug',
    storageBucket: 'parla-debug.firebasestorage.app',
    iosBundleId: 'site.ritom.parla',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCQS1uDvV_gkwp9a8jwD3vJ64GchMyHZF4',
    appId: '1:1022682226044:web:40b0e6897c3df11c2d18f9',
    messagingSenderId: '1022682226044',
    projectId: 'parla-debug',
    authDomain: 'parla-debug.firebaseapp.com',
    storageBucket: 'parla-debug.firebasestorage.app',
    measurementId: 'G-9GDY917KBC',
  );

}