import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../provider/auth_provider.dart';
import '../../provider/user_provider.dart';
import '../home/home_page.dart';
import 'terms_of_service_page.dart';
import 'privacy_policy_page.dart';

class TermsAgreementPage extends ConsumerStatefulWidget {
  const TermsAgreementPage({super.key});

  @override
  ConsumerState<TermsAgreementPage> createState() => _TermsAgreementPageState();
}

class _TermsAgreementPageState extends ConsumerState<TermsAgreementPage> {
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _isSubmitting = false;

  bool get _canProceed => _agreedToTerms && _agreedToPrivacy;

  Future<void> _submitAgreement() async {
    if (!_canProceed || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final user = authRepo.currentUser;

      if (user != null) {
        // 同意状態をFirestoreに保存
        await userRepo.updateTermsAgreement(
          uid: user.uid,
          agreedToTerms: true,
          agreedToPrivacy: true,
          agreedAt: DateTime.now(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                '利用規約とプライバシーポリシー',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TalkENoteをご利用いただく前に、利用規約とプライバシーポリシーをご確認ください。',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildAgreementItem(
                        title: '利用規約に同意する',
                        agreed: _agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value;
                          });
                        },
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TermsOfServicePage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildAgreementItem(
                        title: 'プライバシーポリシーに同意する',
                        agreed: _agreedToPrivacy,
                        onChanged: (value) {
                          setState(() {
                            _agreedToPrivacy = value;
                          });
                        },
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed && !_isSubmitting ? _submitAgreement : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '同意して続ける',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementItem({
    required String title,
    required bool agreed,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: agreed ? AppColors.primary : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: agreed,
              onChanged: (value) => onChanged(value ?? false),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '詳細を確認',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

