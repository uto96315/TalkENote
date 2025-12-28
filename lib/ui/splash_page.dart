import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:talkenote/constants/app_colors.dart';
import 'package:talkenote/provider/auth_provider.dart';
import 'package:talkenote/provider/user_provider.dart';
import 'package:talkenote/ui/home/home_page.dart';
import 'package:talkenote/ui/terms/terms_agreement_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authRepo = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final user = authRepo.currentUser;

    if (user != null) {
      // 利用規約への同意状態をチェック
      final hasAgreed = await userRepo.hasAgreedToTerms(user.uid);
      if (!mounted) return;

      if (hasAgreed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        // 未同意の場合は同意ページに遷移
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TermsAgreementPage()),
        );
      }
    } else {
      // ユーザーが存在しない場合は同意ページに遷移
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TermsAgreementPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // iOS/Androidで真っ白が無難
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: Center(
          child: Lottie.asset(
            'assets/animations/splash.json',
            fit: BoxFit.contain, // ← ポイント：上下左右にフィットして縦長でもいける
          ),
        ),
      ),
    );
  }
}
