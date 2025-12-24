import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class GradientPage extends StatelessWidget {
  const GradientPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient,
        ),
        child: child,
      ),
    );
  }
}

