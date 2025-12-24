/// お問い合わせカテゴリ
enum InquiryCategory {
  /// 操作方法について
  howToUse,

  /// ログインなどの認証について
  authentication,

  /// バグ報告
  bugReport,

  /// 課金について
  billing,

  /// その他
  other,
}

extension InquiryCategoryX on InquiryCategory {
  String get displayName {
    switch (this) {
      case InquiryCategory.howToUse:
        return '操作方法について';
      case InquiryCategory.authentication:
        return 'ログインなどの認証について';
      case InquiryCategory.bugReport:
        return 'バグ報告';
      case InquiryCategory.billing:
        return '課金について';
      case InquiryCategory.other:
        return 'その他';
    }
  }

  String get value {
    switch (this) {
      case InquiryCategory.howToUse:
        return 'howToUse';
      case InquiryCategory.authentication:
        return 'authentication';
      case InquiryCategory.bugReport:
        return 'bugReport';
      case InquiryCategory.billing:
        return 'billing';
      case InquiryCategory.other:
        return 'other';
    }
  }

  static InquiryCategory fromValue(String value) {
    switch (value) {
      case 'howToUse':
        return InquiryCategory.howToUse;
      case 'authentication':
        return InquiryCategory.authentication;
      case 'bugReport':
        return InquiryCategory.bugReport;
      case 'billing':
        return InquiryCategory.billing;
      case 'other':
        return InquiryCategory.other;
      default:
        return InquiryCategory.other;
    }
  }
}

