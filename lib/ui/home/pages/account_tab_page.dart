import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/plan_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../../auth/signup_page.dart';
import '../widgets/account_sidebar.dart';
import '../widgets/gradient_page.dart';
import '../widgets/plan_card.dart';

class AccountTabPage extends ConsumerStatefulWidget {
  const AccountTabPage({super.key});

  @override
  ConsumerState<AccountTabPage> createState() => _AccountTabPageState();
}

class _AccountTabPageState extends ConsumerState<AccountTabPage>
    with SingleTickerProviderStateMixin {
  bool _isSidebarOpen = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // 右からスライド
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
      if (_isSidebarOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _closeSidebar() {
    if (_isSidebarOpen) {
      setState(() {
        _isSidebarOpen = false;
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(userPlanProvider);
    final limitsAsync = ref.watch(userPlanLimitsProvider);
    final monthlyCountAsync = ref.watch(monthlyRecordingCountProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final isAnonymous = authRepo.currentUser?.isAnonymous ?? false;

    return GradientPage(
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'アカウント',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            InkWell(
                              onTap: _toggleSidebar,
                              child: Container(
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.menu,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 32),
                        // 匿名ユーザー向けのアカウント登録促進
                        if (isAnonymous) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'アカウントを登録してください',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '記録を保存するためにアカウントを登録してください。今後、LINEなど他の方法でも登録できるようになります。',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const SignUpPage(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'アカウントを登録',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        // プラン情報
                        planAsync.when(
                          data: (plan) => PlanCard(
                            plan: plan,
                            limits: limitsAsync,
                            monthlyCount: monthlyCountAsync.when(
                              data: (count) => count,
                              loading: () => 0,
                              error: (_, __) => 0,
                            ),
                          ),
                          loading: () => const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                          error: (error, _) => Text(
                            'エラー: $error',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ボトムナビゲーションのスペースを確保
                const SizedBox(height: 96),
              ],
            ),
          ),
          // サイドバーのオーバーレイ（背景を暗くする）
          if (_isSidebarOpen)
            GestureDetector(
              onTap: _closeSidebar,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          // サイドバー
          SlideTransition(
            position: _slideAnimation,
            child: AccountSidebar(
              onClose: _closeSidebar,
              onAccountInfo: () {
                _closeSidebar();
                // TODO: アカウント情報画面への遷移
              },
              onLogout: () async {
                _closeSidebar();
                final authRepo = ref.read(authRepositoryProvider);
                try {
                  await authRepo.signOut();
                  if (mounted) {
                    SnackBarUtils.show(context, 'ログアウトしました');
                  }
                } catch (e) {
                  if (mounted) {
                    SnackBarUtils.show(context, 'ログアウトに失敗しました: $e');
                  }
                }
              },
              onContact: () {
                _closeSidebar();
                // TODO: お問い合わせ画面への遷移
              },
            ),
          ),
        ],
      ),
    );
  }
}

