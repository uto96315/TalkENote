import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:talkenote/constants/app_colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,   // iOS/Androidで真っ白が無難
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: Center(
          child: Lottie.asset(
            'assets/animations/splash.json',
            fit: BoxFit.contain,     // ← ポイント：上下左右にフィットして縦長でもいける
          ),
        ),
      ),
    );
  }
}
