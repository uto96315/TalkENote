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
    try {
      await userRef(uid).update({
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint("🚨Error in updateLastSeen: $error");
      // Silently fail - this is not critical for app functionality
    }
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

  /// ユーザーのメールアドレスを取得
  Future<String?> getUserEmail(String uid) async {
    try {
      final snapshot = await userRef(uid).get();
      if (!snapshot.exists) {
        return null;
      }
      final data = snapshot.data();
      return data?['email'] as String?;
    } catch (e) {
      debugPrint("🚨Error getting user email: $e");
      return null;
    }
  }

  /// 今月の録音回数を取得
  /// ユーザードキュメントに保存されたカウンターから取得
  /// カウンターが存在しない場合は0を返す（初期状態）
  /// 注意: 初期化は行わない（レースコンディションを避けるため）
  ///       初期化は incrementMonthlyRecordingCount 内で行われる
  Future<int> getMonthlyRecordingCount(String uid) async {
    try {
      final snapshot = await userRef(uid).get();
      if (!snapshot.exists) {
        // ユーザードキュメントが存在しない場合は0（初期状態）
        return 0;
      }
      final data = snapshot.data();
      final currentMonthKey = _getCurrentMonthKey();

      // 保存されている月のキーと現在の月が一致するか確認
      final savedMonthKey = data?['monthlyRecordingCountMonth'] as String?;

      // カウンターが存在し、かつ同じ月の場合
      if (savedMonthKey == currentMonthKey) {
        final count = (data?['monthlyRecordingCount'] as int?) ?? 0;
        return count;
      }

      // カウンターが存在しない、または月が変わった場合
      // 0を返す（初期状態または月が変わった状態）
      // 初期化は incrementMonthlyRecordingCount 内で行われる
      return 0;
    } catch (e) {
      debugPrint("🚨Error getting monthly recording count: $e");
      // エラー時は0を返す（安全側に倒す）
      return 0;
    }
  }

  /// 月間録音回数をインクリメント（録音作成時に呼ぶ）
  /// 月が変わっている場合はリセットしてからインクリメント
  /// カウンターが存在しない場合は0から開始（既存録音データとの整合性は保持されないが、
  /// 新規システムなので問題なし。正確性が必要な場合は別途同期処理を実装）
  /// 戻り値: インクリメント後のカウント数（エラー時は-1）
  Future<int> incrementMonthlyRecordingCount(String uid) async {
    try {
      final currentMonthKey = _getCurrentMonthKey();
      final ref = userRef(uid);

      int newCount = 0;
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        final savedMonthKey = data?['monthlyRecordingCountMonth'] as String?;

        int currentCount = 0;

        // カウンターが存在しない、または月が変わった場合
        if (savedMonthKey == null || savedMonthKey != currentMonthKey) {
          // 0から開始（リセットまたは初期化）
          // 注意: 既存の録音データとの整合性は保持されないが、
          // 新規システムなので問題なし。既存データを考慮する場合は
          // トランザクション外でクエリし、その結果をここで使用する必要がある
          debugPrint(
              "📊Resetting/Initializing monthly counter for month: $currentMonthKey (previous: $savedMonthKey)");
          currentCount = 0;
        } else {
          // 同じ月の場合は現在のカウントを取得
          currentCount = (data?['monthlyRecordingCount'] as int?) ?? 0;
          debugPrint(
              "📊Incrementing monthly counter: $currentCount -> ${currentCount + 1} (month: $currentMonthKey)");
        }

        newCount = currentCount + 1;
        transaction.set(
            ref,
            {
              'monthlyRecordingCount': newCount,
              'monthlyRecordingCountMonth': currentMonthKey,
              'monthlyRecordingCountUpdatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true)); // トランザクション内で処理するため、merge: trueで問題なし
      });

      debugPrint(
          "✅Monthly recording count incremented successfully: $newCount");
      return newCount;
    } catch (e, stackTrace) {
      debugPrint("🚨Error incrementing monthly recording count: $e");
      debugPrint("Stack trace: $stackTrace");
      // エラーが発生しても録音の保存は続行する
      // ただし、呼び出し側でエラーを検知できるように-1を返す
      return -1;
    }
  }

  /// 現在の月をキーとして取得（例: "2024-01"）
  String _getCurrentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// 利用規約への同意状態を更新
  Future<void> updateTermsAgreement({
    required String uid,
    required bool agreedToTerms,
    required bool agreedToPrivacy,
  }) async {
    try {
      await userRef(uid).update({
        'agreedToTerms': agreedToTerms,
        'agreedToPrivacy': agreedToPrivacy,
        'agreedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🚨Error updating terms agreement: $e");
      rethrow;
    }
  }

  /// 利用規約への同意状態を取得
  Future<bool> hasAgreedToTerms(String uid) async {
    try {
      final snapshot = await userRef(uid).get();
      if (!snapshot.exists) {
        return false;
      }
      final data = snapshot.data();
      final agreedToTerms = data?['agreedToTerms'] as bool?;
      final agreedToPrivacy = data?['agreedToPrivacy'] as bool?;
      return (agreedToTerms ?? false) && (agreedToPrivacy ?? false);
    } catch (e) {
      debugPrint("🚨Error getting terms agreement: $e");
      return false;
    }
  }
}
