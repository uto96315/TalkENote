/// ユーザープラン定義
enum UserPlan {
  /// 無課金（フリー）
  free,

  /// 課金
  paid,

  /// プレミアム+
  premiumPlus,
}

/// プラン制限
class PlanLimits {
  const PlanLimits({
    required this.maxRecordingDuration,
    required this.monthlyRecordingLimit,
    required this.showAds,
  });

  /// 最大録音時間
  final Duration maxRecordingDuration;

  /// 月間録音回数制限
  final int monthlyRecordingLimit;

  /// 広告を表示するか
  final bool showAds;

  /// プランに応じた制限を取得
  static PlanLimits forPlan(UserPlan plan) {
    switch (plan) {
      case UserPlan.free:
        return const PlanLimits(
          maxRecordingDuration: Duration(minutes: 2),
          monthlyRecordingLimit: 5,
          showAds: true,
        );
      case UserPlan.paid:
        return const PlanLimits(
          maxRecordingDuration: Duration(minutes: 5),
          monthlyRecordingLimit: 15,
          showAds: false,
        );
      case UserPlan.premiumPlus:
        return const PlanLimits(
          maxRecordingDuration: Duration(minutes: 15),
          monthlyRecordingLimit: 30,
          showAds: false,
        );
    }
  }

  /// プラン名を取得
  static String planName(UserPlan plan) {
    switch (plan) {
      case UserPlan.free:
        return '無課金';
      case UserPlan.paid:
        return '課金';
      case UserPlan.premiumPlus:
        return 'プレミアム+';
    }
  }
}

/// プラン関連のユーティリティ
extension UserPlanExtension on UserPlan {
  /// 表示用のプラン名を取得（日本語）
  String get displayName => PlanLimits.planName(this);

  /// Firestoreに保存する値（英語）
  String get value {
    switch (this) {
      case UserPlan.free:
        return 'free';
      case UserPlan.paid:
        return 'paid';
      case UserPlan.premiumPlus:
        return 'premiumPlus';
    }
  }

  /// 文字列からプランを取得
  static UserPlan fromValue(String value) {
    switch (value) {
      case 'free':
        return UserPlan.free;
      case 'paid':
        return UserPlan.paid;
      case 'premiumPlus':
        return UserPlan.premiumPlus;
      default:
        return UserPlan.free;
    }
  }

  /// プラン制限を取得
  PlanLimits get limits => PlanLimits.forPlan(this);
}

