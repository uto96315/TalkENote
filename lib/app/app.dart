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
    // Handle errors gracefully - don't block app startup
    authRepo.signInAnonymouslyIfNeeded().then((user) {
      if (user != null) {
        userRepo.createIfNotExists(
          uid: user.uid,
          isAnonymous: user.isAnonymous,
        ).catchError((error) {
          debugPrint('Failed to create user: $error');
          // Continue even if user creation fails
        });
      }
    }).catchError((error) {
      debugPrint('Failed to sign in anonymously: $error');
      // Continue app initialization even if auth fails
      return null; // Return null to satisfy the Future type
    });

    return MaterialApp(
      title: 'TalkENote',
      routes: appRoutes,
      initialRoute: '/',
      // theme: AppTheme.light,
    );
  }
}
