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

  /// 匿名ユーザーをメールアドレスで登録
  Future<UserCredential?> linkWithEmail({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw Exception('匿名ユーザーではありません');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final userCredential = await user.linkWithCredential(credential);
      return userCredential;
    } catch (e) {
      debugPrint('メールアドレス登録に失敗: $e');
      rethrow;
    }
  }

  /// メールアドレスとパスワードでサインアップ
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      debugPrint('メールアドレス登録に失敗: $e');
      rethrow;
    }
  }

  /// ログアウト
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('ログアウトに失敗: $e');
      rethrow;
    }
  }
}
