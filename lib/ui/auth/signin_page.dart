import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../constants/app_colors.dart';
import '../../provider/auth_provider.dart';
import '../../provider/user_provider.dart';
import '../../utils/snackbar_utils.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final currentUser = authRepo.currentUser;

      // 匿名ユーザーの場合は先にログアウト
      if (currentUser != null && currentUser.isAnonymous) {
        await authRepo.signOut();
      }

      // 既存のアカウントにログイン
      final userCredential = await authRepo.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential?.user != null) {
        final user = userCredential!.user!;
        final email = _emailController.text.trim();

        // ユーザードキュメントを作成/更新
        await userRepo.createIfNotExists(
          uid: user.uid,
          isAnonymous: false,
        );

        // メールアドレスとisAnonymousを更新
        await userRepo.updateUserInfo(
          uid: user.uid,
          email: email,
          isAnonymous: false,
        );

        if (mounted) {
          SnackBarUtils.show(context, 'ログインしました');
          Navigator.of(context).pop();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'ログインに失敗しました';
        if (e.code == 'user-not-found') {
          message = 'このメールアドレスは登録されていません';
        } else if (e.code == 'wrong-password') {
          message = 'パスワードが正しくありません';
        } else if (e.code == 'invalid-email') {
          message = 'メールアドレスの形式が正しくありません';
        } else if (e.code == 'user-disabled') {
          message = 'このアカウントは無効化されています';
        } else if (e.code == 'too-many-requests') {
          message = 'ログイン試行回数が多すぎます。しばらく待ってから再度お試しください';
        } else if (e.code == 'email-already-in-use') {
          message = 'このメールアドレスは既に使用されています。ログインしてください';
        } else if (e.code == 'invalid-credential') {
          message = 'メールアドレスまたはパスワードが正しくありません';
        }
        SnackBarUtils.show(context, message);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.show(context, 'ログインに失敗しました: $e');
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
                      'ログイン',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'アカウントにログインしてください',
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
                        hintText: 'メールアドレス',
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
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSignIn(),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'パスワード',
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
                            setState(() => _obscurePassword = !_obscurePassword);
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // ログインボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignIn,
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
                                'ログイン',
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
    );
  }
}

