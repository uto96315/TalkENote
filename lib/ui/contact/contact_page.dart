import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/inquiry_category.dart';
import '../../provider/auth_provider.dart';
import '../../provider/inquiry_provider.dart';
import '../../provider/user_provider.dart';
import '../../utils/snackbar_utils.dart';

class ContactPage extends ConsumerStatefulWidget {
  const ContactPage({super.key});

  @override
  ConsumerState<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends ConsumerState<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _contentFocusNode = FocusNode();
  InquiryCategory? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _contentFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      SnackBarUtils.show(context, 'カテゴリを選択してください');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final inquiryRepo = ref.read(inquiryRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final currentUser = authRepo.currentUser;

      if (currentUser == null) {
        SnackBarUtils.show(context, 'ログインが必要です');
        return;
      }

      // ユーザーのメールアドレスを取得
      final userEmail = await userRepo.getUserEmail(currentUser.uid);

      // Firestoreに保存（自動送信）
      await inquiryRepo.submitInquiry(
        userId: currentUser.uid,
        userEmail: userEmail,
        category: _selectedCategory!,
        content: _contentController.text.trim(),
      );

      if (mounted) {
        SnackBarUtils.show(context, 'お問い合わせを送信しました');
        // キーボードを閉じる
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.show(context, '送信に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0 && _contentFocusNode.hasFocus;

    return GestureDetector(
      onTap: () {
        // 画面タップでキーボードを下げる
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            SizedBox.expand(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.homeGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // 戻るボタン
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // タイトル
                    const Text(
                      'お問い合わせ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ご質問やご意見をお聞かせください',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // カテゴリ選択
                    Text(
                      'カテゴリ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...InquiryCategory.values.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedCategory == category
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedCategory == category
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.3),
                                width: _selectedCategory == category ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedCategory == category
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: _selectedCategory == category
                                      ? AppColors.primary
                                      : Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  category.displayName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedCategory == category
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    // 問い合わせ内容
                    Text(
                      'お問い合わせ内容',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      maxLines: 10,
                      minLines: 5,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'お問い合わせ内容を入力してください',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'お問い合わせ内容を入力してください';
                        }
                        if (value.trim().length < 10) {
                          return 'お問い合わせ内容は10文字以上で入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // 送信ボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                ),
                              )
                            : const Text(
                                '送信',
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
            ),
          ),
            ),
            // キーボードの上に表示する完了ボタンのツールバー
            if (isKeyboardVisible)
              Positioned(
                bottom: keyboardHeight,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            // 完了ボタンでキーボードを下げる
                            FocusScope.of(context).unfocus();
                          },
                          child: const Text(
                            '完了',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
