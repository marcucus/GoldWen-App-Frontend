import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const String _androidApiKey = "AIzaSyBvOiuDOTuFmGK2z9JdEeQhCxXLJ4M5S6R";
  static const String _androidAppId = "1:1234567890:android:abcdef123456789";
  static const String _androidMessagingSenderId = "1234567890";
  static const String _androidProjectId = "goldwen-app";
  
  static const String _iosApiKey = "AIzaSyBvOiuDOTuFmGK2z9JdEeQhCxXLJ4M5S6R";
  static const String _iosAppId = "1:1234567890:ios:fedcba987654321";
  static const String _iosMessagingSenderId = "1234567890";
  static const String _iosProjectId = "goldwen-app";
  static const String _iosBundleId = "com.goldwen.app";
  
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _androidApiKey,
    appId: _androidAppId,
    messagingSenderId: _androidMessagingSenderId,
    projectId: _androidProjectId,
    storageBucket: '$_androidProjectId.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _iosApiKey,
    appId: _iosAppId,
    messagingSenderId: _iosMessagingSenderId,
    projectId: _iosProjectId,
    storageBucket: '$_iosProjectId.appspot.com',
    iosBundleId: _iosBundleId,
  );
}

/// Note: These are placeholder values for development.
/// In production, replace these with actual Firebase configuration values:
/// 1. Run `flutterfire configure` to generate proper configuration
/// 2. Or manually add google-services.json (Android) and GoogleService-Info.plist (iOS)
/// 3. Replace the placeholder values above with real Firebase project values