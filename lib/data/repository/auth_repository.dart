import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  // 匿名認証
  Future<User?> signInAnonymouslyIfNeeded() async {
    final user = _auth.currentUser;
    if (user != null) return user;

    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  User? get currentUser => _auth.currentUser;
}
