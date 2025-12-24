import 'package:flutter/material.dart';

enum HomeTab { home, record, note, account }

extension HomeTabX on HomeTab {
  String get name {
    switch (this) {
      case HomeTab.home:
        return 'ホーム';
      case HomeTab.record:
        return '録音';
      case HomeTab.note:
        return '記録';
      case HomeTab.account:
        return 'アカウント';
    }
  }

  IconData get icon {
    switch (this) {
      case HomeTab.home:
        return Icons.home_outlined;
      case HomeTab.record:
        return Icons.add_circle_outline;
      case HomeTab.note:
        return Icons.description;
      case HomeTab.account:
        return Icons.person_outline;
    }
  }
}
