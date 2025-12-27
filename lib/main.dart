import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'service/notification_service.dart';
import 'service/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: Failed to load .env file: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Continue app initialization even if Firebase fails
    // The app can still function in offline mode
  }

  // ProviderContainerを作成（通知サービスに渡すため）
  final container = ProviderContainer();

  // 通知サービスを初期化（ProviderContainerを渡して、通知タップ時にナビゲーションできるようにする）
  try {
    await NotificationService().initialize(container: container);
  } catch (e) {
    debugPrint('Error initializing notification service: $e');
    // Continue app initialization even if notification service fails
  }

  // AdMobを初期化
  try {
    await AdService().initialize();
  } catch (e) {
    debugPrint('Error initializing AdMob: $e');
    // Continue app initialization even if AdMob fails
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TalkENoteApp(),
    ),
  );
}
