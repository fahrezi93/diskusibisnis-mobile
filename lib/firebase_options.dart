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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAkakmS6sNZsX3wrpCozGE3xW9kf3-qX5c',
    authDomain: 'diskusi-bisnis.firebaseapp.com',
    projectId: 'diskusi-bisnis',
    storageBucket: 'diskusi-bisnis.firebasestorage.app',
    messagingSenderId: '642856781888',
    appId: '1:642856781888:web:3d267886b1248a61c5f7a5',
    measurementId: 'G-0KV9EXTLFP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDdFMEWF8M_RzQR8nmrT4LLDoScVs76rLE',
    appId: '1:642856781888:android:38f07ab8f8f886c5c5f7a5',
    messagingSenderId: '642856781888',
    projectId: 'diskusi-bisnis',
    storageBucket: 'diskusi-bisnis.firebasestorage.app',
  );
}
