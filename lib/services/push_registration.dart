import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:zatgo_dart_sdk/zatgo_dart_sdk.dart';

import 'session.dart';

/// Obtains an FCM token (when Firebase is configured) and registers it with ERPNext.
class PushRegistration {
  PushRegistration(this.session);

  final ProjectTrackerSession session;

  Future<String> registerIfPossible() async {
    if (kIsWeb) {
      return 'FCM registration skipped on web (scaffold)';
    }

    try {
      await Firebase.initializeApp();
    } catch (e) {
      return 'Firebase not configured yet ($e). Add google-services / GoogleService-Info '
          'then re-run. Token registration API is ready.';
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) {
      return 'No FCM token available';
    }

    final platform = Platform.isIOS ? 'ios' : 'android';
    final envelope = await session.store.callMethod(
      ZatGoApiMethods.devicesRegisterToken,
      args: {
        'token': token,
        'platform': platform,
        'app_id': 'project_tracker_mobile',
      },
    );
    final data = envelope.data;
    final name = data is Map ? data['name'] : null;
    return 'Registered token success=${envelope.success} name=$name';
  }
}
