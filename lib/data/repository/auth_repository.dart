import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  // 匿名認証
  Future<User?> signInAnonymouslyIfNeeded() async {
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint("userが存在しているためAuthへの登録はスキップします。$user");
      return user;
    }
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } catch (error) {
      debugPrint("匿名認証でエラーが発生: $error");
      return null;
    }
  }

  User? get currentUser => _auth.currentUser;
}
