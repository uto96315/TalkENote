import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/auth_provider.dart';
import 'routes.dart';

class TalkENoteApp extends ConsumerWidget {
  const TalkENoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔑 起動時に匿名認証（1回だけ）
    ref.read(authRepositoryProvider).signInAnonymouslyIfNeeded();

    return MaterialApp(
      title: 'TalkENote',
      routes: appRoutes,
      initialRoute: '/',
      // theme: AppTheme.light,
    );
  }
}
