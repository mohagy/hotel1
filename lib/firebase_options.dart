// File generated using existing Firebase project configuration
// Firebase project: flutter-hotel-8efbf

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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBLV8T9Wwmcgnb8OvoeB8bofqEYe2IZW_M',
    appId: '1:635259139186:web:886df2615ded00f87e3eeb',
    messagingSenderId: '635259139186',
    projectId: 'flutter-hotel-8efbf',
    authDomain: 'flutter-hotel-8efbf.firebaseapp.com',
    storageBucket: 'flutter-hotel-8efbf.firebasestorage.app',
    measurementId: 'G-9XH4Q0EM2N',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLV8T9Wwmcgnb8OvoeB8bofqEYe2IZW_M',
    appId: '1:635259139186:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '635259139186',
    projectId: 'flutter-hotel-8efbf',
    storageBucket: 'flutter-hotel-8efbf.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBLV8T9Wwmcgnb8OvoeB8bofqEYe2IZW_M',
    appId: '1:635259139186:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '635259139186',
    projectId: 'flutter-hotel-8efbf',
    storageBucket: 'flutter-hotel-8efbf.firebasestorage.app',
    iosBundleId: 'com.hotel.hotelManagement',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBLV8T9Wwmcgnb8OvoeB8bofqEYe2IZW_M',
    appId: '1:635259139186:macos:YOUR_MACOS_APP_ID',
    messagingSenderId: '635259139186',
    projectId: 'flutter-hotel-8efbf',
    storageBucket: 'flutter-hotel-8efbf.firebasestorage.app',
    iosBundleId: 'com.hotel.hotelManagement',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBLV8T9Wwmcgnb8OvoeB8bofqEYe2IZW_M',
    appId: '1:635259139186:windows:YOUR_WINDOWS_APP_ID',
    messagingSenderId: '635259139186',
    projectId: 'flutter-hotel-8efbf',
    storageBucket: 'flutter-hotel-8efbf.firebasestorage.app',
  );
}

