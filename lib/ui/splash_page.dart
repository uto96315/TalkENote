import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:talkenote/constants/app_colors.dart';
import 'package:talkenote/ui/home/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

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
