import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'data/local/hive_boxes.dart';
import 'data/repositories/settings_repository.dart';
import 'firebase_options.dart';

// Geriye dönük uyumluluk için PawCareApp sınıfını dışa aktarır.
export 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase / Messaging initialization failed: $e');
  }
  await HiveBoxes.init();
  final settingsRepo = await SettingsRepository.create();
  runApp(PawCareApp(settingsRepository: settingsRepo));
}
