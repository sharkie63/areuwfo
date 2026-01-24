import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// This is the function that will be called from our test file.
void setupFirebaseCoreMocks() {
  // Use a mock method call handler for the Firebase core channel.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_core'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'Firebase#initializeCore') {
        // This is the crucial part. We return a list of mock app data.
        return <Map<String, dynamic>>[
          {
            'name': '[DEFAULT]', // The default app instance
            'options': {
              'apiKey': 'mock_api_key',
              'appId': 'mock_app_id',
              'messagingSenderId': 'mock_sender_id',
              'projectId': 'mock_project_id',
            },
            'pluginConstants': {},
          }
        ];
      } else if (methodCall.method == 'Firebase#initializeApp') {
        // This handles named app initializations.
        return {
          'name': methodCall.arguments['appName'],
          'options': methodCall.arguments['options'],
          'pluginConstants': {},
        };
      }
      return null;
    },
  );
}

// This function will be used to clear the mock handler after tests.
void tearDownFirebaseCoreMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_core'), null);
}
