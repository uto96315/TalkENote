import 'package:flutter/material.dart';

import '../ui/home/home_page.dart';
import '../ui/splash_page.dart';
// import '../ui/result/result_page.dart';
// import '../ui/log/log_page.dart';

/// ルート名を一元管理
class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  // static const result = '/result';
  // static const log = '/log';
}

/// routes 定義
final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.splash: (_) => const SplashPage(),
  AppRoutes.home: (_) => const HomePage(),
  // AppRoutes.result: (_) => const ResultPage(),
  // AppRoutes.log: (_) => const LogPage(),
};
