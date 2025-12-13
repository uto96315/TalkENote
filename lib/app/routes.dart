import 'package:flutter/material.dart';

// 仮の画面（あとで差し替える）
import '../ui/home/home_page.dart';
// import '../ui/result/result_page.dart';
// import '../ui/log/log_page.dart';

/// ルート名を一元管理
class AppRoutes {
  static const home = '/';
  // static const result = '/result';
  // static const log = '/log';
}

/// routes 定義
final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.home: (_) => const HomePage(),
  // AppRoutes.result: (_) => const ResultPage(),
  // AppRoutes.log: (_) => const LogPage(),
};
