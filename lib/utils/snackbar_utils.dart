import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 統一されたSnackBarを表示するユーティリティ
class SnackBarUtils {
  /// 白っぽくて吹き出しっぽいデザインのSnackBarを表示
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        elevation: 8,
        duration: duration,
      ),
    );
  }
}
