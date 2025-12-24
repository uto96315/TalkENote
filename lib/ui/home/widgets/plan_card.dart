import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/user_plan.dart';
import '../../../utils/snackbar_utils.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.limits,
    required this.monthlyCount,
  });

  final UserPlan plan;
  final PlanLimits limits;
  final int monthlyCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '現在のプラン',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  plan.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PlanInfoRow(
            label: '最大録音時間',
            value: _formatDuration(limits.maxRecordingDuration),
          ),
          const SizedBox(height: 12),
          PlanInfoRow(
            label: '月間録音回数',
            value: '$monthlyCount / ${limits.monthlyRecordingLimit}',
          ),
          const SizedBox(height: 12),
          PlanInfoRow(
            label: '広告',
            value: limits.showAds ? '表示' : '非表示',
          ),
          if (plan != UserPlan.premiumPlus) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: プランアップグレード画面への遷移
                SnackBarUtils.show(context, 'プランアップグレード機能は準備中です');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'プランをアップグレード',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    return '$minutes分';
  }
}

class PlanInfoRow extends StatelessWidget {
  const PlanInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

