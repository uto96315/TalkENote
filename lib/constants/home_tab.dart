import 'package:flutter/material.dart';

enum HomeTab {
  home,
  note,
  account,
}

final _names = {
  HomeTab.home: "ホーム",
  HomeTab.note: "記録",
  HomeTab.account: "アカウント"
};

final _pages = {
  HomeTab.home: const SizedBox(), // TODO: 後ほど正式なページに差し替え
  HomeTab.note: const SizedBox(),
  HomeTab.account: const SizedBox(),
};

final _icons = {}; // アイコンを定義

extension HomeTabExt on HomeTab {
  String get name => _names[this]!;
  Widget get page => _pages[this]!;
}
