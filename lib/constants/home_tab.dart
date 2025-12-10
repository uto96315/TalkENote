import 'package:flutter/material.dart';

enum HomeTab {
  home(
    name: 'ホーム',
    page: SizedBox(), // TODO: 後ほど正式なページに差し替え
  ),
  note(
    name: '記録',
    page: SizedBox(),
  ),
  account(
    name: 'アカウント',
    page: SizedBox(),
  );

  const HomeTab({
    required this.name,
    required this.page,
  });

  final String name;
  final Widget page;
}
