import 'package:flutter/material.dart';

enum HomeTab { home, note, account }

extension HomeTabX on HomeTab {
  String get name {
    switch (this) {
      case HomeTab.home:
        return 'ホーム';
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
      case HomeTab.note:
        return Icons.note_alt_outlined;
      case HomeTab.account:
        return Icons.person_outline;
    }
  }
}
