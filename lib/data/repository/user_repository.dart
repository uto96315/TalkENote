import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  UserRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<void> createIfNotExists({
    required String uid,
    required bool isAnonymous,
  }) async {
    final ref = userRef(uid);

    try {
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        await ref.set({
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeenAt': FieldValue.serverTimestamp(),
          'isAnonymous': isAnonymous,
          'nativeLang': 'ja',
          'learningLang': 'en',
        });
      }
    } catch (error) {
      debugPrint("🚨Error in createIfNotExists: $error");
    }
  }

  Future<void> updateLastSeen(String uid) async {
    await userRef(uid).update({
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }
}
