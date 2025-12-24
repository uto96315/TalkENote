import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../constants/app_colors.dart';
import '../../data/repository/auth_repository.dart';
import '../../data/repository/user_repository.dart';
import '../../provider/auth_provider.dart';
import '../../provider/user_provider.dart';
import '../../utils/snackbar_utils.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final currentUser = authRepo.currentUser;

      UserCredential? userCredential;

      if (currentUser != null && currentUser.isAnonymous) {
        // 匿名ユーザーの場合はリンク
        userCredential = await authRepo.linkWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // 新規登録
        userCredential = await authRepo.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (userCredential?.user != null) {
        // ユーザードキュメントを作成/更新
        await userRepo.createIfNotExists(
          uid: userCredential!.user!.uid,
          isAnonymous: false,
        );

        if (mounted) {
          SnackBarUtils.show(context, 'アカウントを登録しました');
          Navigator.of(context).pop();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = '登録に失敗しました';
        if (e.code == 'weak-password') {
          message = 'パスワードが弱すぎます';
        } else if (e.code == 'email-already-in-use') {
          message = 'このメールアドレスは既に使用されています';
        } else if (e.code == 'invalid-email') {
          message = 'メールアドレスの形式が正しくありません';
        }
        SnackBarUtils.show(context, message);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.show(context, '登録に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
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
                      'アカウントを登録',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '記録を保存するためにアカウントを登録してください',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // メールアドレス入力
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'メールアドレス',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        hintText: 'example@email.com',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
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
                        if (value == null || value.isEmpty) {
                          return 'メールアドレスを入力してください';
                        }
                        if (!value.contains('@')) {
                          return 'メールアドレスの形式が正しくありません';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // パスワード入力
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'パスワード',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        hintText: '8文字以上',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
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
                        if (value == null || value.isEmpty) {
                          return 'パスワードを入力してください';
                        }
                        if (value.length < 8) {
                          return 'パスワードは8文字以上にしてください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // パスワード確認入力
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSignUp(),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'パスワード（確認）',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        hintText: 'パスワードを再入力',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword =
                                !_obscureConfirmPassword);
                          },
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
                        if (value == null || value.isEmpty) {
                          return 'パスワードを再入力してください';
                        }
                        if (value != _passwordController.text) {
                          return 'パスワードが一致しません';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // 登録ボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
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
                                'アカウントを登録',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 注意書き
                    Text(
                      '※今後、LINEなど他の方法でも登録できるようになります',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
