import 'package:flutter/material.dart';

/// Centralized color definitions for the app.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF62E245);
  static const Color secondary = Color(0xFF4A90E2);
  static const Color background = Color(0xFFF5F7FB);
  static const Color textPrimary = Color(0xFF1F2430);
  static const Color textSecondary = Color.fromARGB(255, 132, 137, 145);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // グラデーション
  static const gradientTop = Color(0xFFA5F6A8);
  static const gradientBottom = Color(0xFF62E245);

  static const homeGradientTop = Color.fromARGB(255, 177, 245, 179);
  static final LinearGradient homeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      homeGradientTop,
      primary.withOpacity(0.6),
    ],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      gradientTop,
      gradientBottom,
    ],
  );
}
