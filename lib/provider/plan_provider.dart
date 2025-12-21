import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/user_plan.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

/// 現在のユーザーのプランを取得するプロバイダー
final userPlanProvider = FutureProvider<UserPlan>((ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final userRepo = ref.read(userRepositoryProvider);
  final user = authRepo.currentUser;
  if (user == null) {
    return UserPlan.free;
  }
  return await userRepo.getUserPlan(user.uid);
});

/// 現在のユーザーのプラン制限を取得するプロバイダー
final userPlanLimitsProvider = Provider<PlanLimits>((ref) {
  final planAsync = ref.watch(userPlanProvider);
  return planAsync.when(
    data: (plan) => PlanLimits.forPlan(plan),
    loading: () => PlanLimits.forPlan(UserPlan.free),
    error: (_, __) => PlanLimits.forPlan(UserPlan.free),
  );
});

/// 広告を表示するかどうかを判定するプロバイダー
final shouldShowAdsProvider = Provider<bool>((ref) {
  final limits = ref.watch(userPlanLimitsProvider);
  return limits.showAds;
});

/// 月間録音回数を取得するプロバイダー
final monthlyRecordingCountProvider = FutureProvider<int>((ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final userRepo = ref.read(userRepositoryProvider);
  final user = authRepo.currentUser;
  if (user == null) {
    return 0;
  }
  return await userRepo.getMonthlyRecordingCount(user.uid);
});

