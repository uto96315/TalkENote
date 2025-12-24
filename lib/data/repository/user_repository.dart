import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/user_plan.dart';

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
          'plan': UserPlan.free.value, // デフォルトは無課金
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

  /// ユーザーのプランを取得
  Future<UserPlan> getUserPlan(String uid) async {
    try {
      final snapshot = await userRef(uid).get();
      if (!snapshot.exists) {
        return UserPlan.free; // デフォルトは通常ユーザー
      }
      final data = snapshot.data();
      final planStr = data?['plan'] as String?;
      if (planStr == null) {
        return UserPlan.free;
      }
      // 文字列からenumに変換
      // 後方互換性: 日本語の値も処理
      if (planStr == '無課金') {
        return UserPlan.free;
      } else if (planStr == '課金') {
        return UserPlan.paid;
      } else if (planStr == 'プレミアム+') {
        return UserPlan.premiumPlus;
      }
      return UserPlanExtension.fromValue(planStr);
    } catch (e) {
      debugPrint("🚨Error getting user plan: $e");
      return UserPlan.free;
    }
  }

  /// ユーザーのプランを更新
  Future<void> updateUserPlan(String uid, UserPlan plan) async {
    try {
      await userRef(uid).update({
        'plan': plan.value,
        'planUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🚨Error updating user plan: $e");
      rethrow;
    }
  }

  /// ユーザー情報を更新（メールアドレス登録時など）
  Future<void> updateUserInfo({
    required String uid,
    String? email,
    bool? isAnonymous,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (email != null) {
        updateData['email'] = email;
      }
      if (isAnonymous != null) {
        updateData['isAnonymous'] = isAnonymous;
      }
      if (updateData.isEmpty) {
        return; // 更新するデータがない場合は何もしない
      }
      await userRef(uid).update(updateData);
    } catch (e) {
      debugPrint("🚨Error updating user info: $e");
      rethrow;
    }
  }

  /// 今月の録音回数を取得
  Future<int> getMonthlyRecordingCount(String uid) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);

      final recordingsRef = _firestore.collection('recordings');
      final snapshot = await recordingsRef
          .where('userId', isEqualTo: uid)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfMonth))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint("🚨Error getting monthly recording count: $e");
      return 0;
    }
  }
}
