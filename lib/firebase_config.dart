import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const useEmulators = bool.fromEnvironment('USE_EMULATORS', defaultValue: true);
const _project = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _appId = String.fromEnvironment('FIREBASE_APP_ID');
const _sender = String.fromEnvironment('FIREBASE_SENDER_ID');
const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

Future<void> startFirebase() async {
  if (!useEmulators &&
      [_project, _apiKey, _appId, _sender].any((value) => value.isEmpty)) {
    throw StateError(
      'Cấu hình Firebase còn thiếu. Xem README để kết nối Firebase thật.',
    );
  }

  await Firebase.initializeApp(
    options: useEmulators
        ? FirebaseOptions(
            apiKey: 'demo-key',
            appId: kIsWeb
                ? '1:123456789:web:0000000000000000'
                : '1:123456789:android:0000000000000000',
            messagingSenderId: '123456789',
            projectId: 'demo-kho-san-pham',
            authDomain: 'demo-kho-san-pham.firebaseapp.com',
          )
        : FirebaseOptions(
            apiKey: _apiKey,
            appId: _appId,
            messagingSenderId: _sender,
            projectId: _project,
            authDomain: _authDomain.isEmpty ? null : _authDomain,
          ),
  );
  if (useEmulators) {
    const configuredHost = String.fromEnvironment('EMULATOR_HOST');
    final host = configuredHost.isNotEmpty
        ? configuredHost
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    await FirebaseAuth.instance.useAuthEmulator(
      host,
      9099,
      automaticHostMapping: false,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      host,
      8080,
      automaticHostMapping: false,
    );
  }
}
