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
    apiKey: 'AIzaSyBgCc-J7sjzGz8d-JgdzLA4QfvIsM12RYg',
    appId: '1:278306466027:web:6be6da326c2c17b5f376ae',
    messagingSenderId: '278306466027',
    projectId: 'placeme-firebase',
    authDomain: 'placeme-firebase.firebaseapp.com',
    storageBucket: 'placeme-firebase.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBBT9k8ZKodceCNBJPPN6x8xuCtx_VTc0s',
    appId: '1:278306466027:android:7d479060435e76a9f376ae',
    messagingSenderId: '278306466027',
    projectId: 'placeme-firebase',
    storageBucket: 'placeme-firebase.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCz9lbsTq40lfi5RcXg7S_k1MrPo6KN9OQ',
    appId: '1:278306466027:ios:58000d2a7933d056f376ae',
    messagingSenderId: '278306466027',
    projectId: 'placeme-firebase',
    storageBucket: 'placeme-firebase.firebasestorage.app',
    iosClientId: '278306466027-hdc3rob99cqlv9gv6ebennhlo6voskqs.apps.googleusercontent.com',
    iosBundleId: 'com.example.placeMe',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCz9lbsTq40lfi5RcXg7S_k1MrPo6KN9OQ',
    appId: '1:278306466027:ios:58000d2a7933d056f376ae',
    messagingSenderId: '278306466027',
    projectId: 'placeme-firebase',
    storageBucket: 'placeme-firebase.firebasestorage.app',
    iosClientId: '278306466027-hdc3rob99cqlv9gv6ebennhlo6voskqs.apps.googleusercontent.com',
    iosBundleId: 'com.example.placeMe',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBgCc-J7sjzGz8d-JgdzLA4QfvIsM12RYg',
    appId: '1:278306466027:web:1b66995d4055ca82f376ae',
    messagingSenderId: '278306466027',
    projectId: 'placeme-firebase',
    authDomain: 'placeme-firebase.firebaseapp.com',
    storageBucket: 'placeme-firebase.firebasestorage.app',
  );
}
