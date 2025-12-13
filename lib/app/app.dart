import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkenote/provider/user_provider.dart';

import '../provider/auth_provider.dart';
import 'routes.dart';

class TalkENoteApp extends ConsumerWidget {
  const TalkENoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    // 🔑 起動時に匿名認証（1回だけ）
    ref.read(authRepositoryProvider).signInAnonymouslyIfNeeded();

    authRepo.signInAnonymouslyIfNeeded().then((user) {
      if (user != null) {
        userRepo.createIfNotExists(
          uid: user.uid,
          isAnonymous: user.isAnonymous,
        );
      }
    });

    return MaterialApp(
      title: 'TalkENote',
      routes: appRoutes,
      initialRoute: '/',
      // theme: AppTheme.light,
    );
  }
}
