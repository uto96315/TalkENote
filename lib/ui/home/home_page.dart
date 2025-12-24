import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../constants/app_colors.dart';
import '../../constants/home_tab.dart';
import '../../constants/user_plan.dart';
import '../../provider/home_provider.dart';
import '../../provider/plan_provider.dart';
import '../../provider/recording_provider.dart';
import '../../provider/auth_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../auth/signup_page.dart';
import 'widgets/home_tab.dart' show RecordTabPage;
import 'widgets/recordings_list.dart';

final currentTabProvider = StateProvider<HomeTab>((ref) => HomeTab.home);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _tabSoundPlayer = AudioPlayer();

  @override
  void dispose() {
    _tabSoundPlayer.dispose();
    super.dispose();
  }

  Future<void> _playTabSound() async {
    try {
      await _tabSoundPlayer.setAsset('assets/sounds/move_tab.mp3');
      await _tabSoundPlayer.play();
    } catch (e) {
      debugPrint('Failed to play tab sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(currentTabProvider);
    final notifier = ref.read(currentTabProvider.notifier);
    final tabs = HomeTab.values;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: tabs.indexOf(tab),
        children: const [
          _HomeTabPage(),
          RecordTabPage(),
          _NoteTabPage(),
          _AccountTabPage(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _FloatingNavBar(
          tabs: tabs,
          current: tab,
          onTap: (next) {
            // 同じタブをタップした場合は音を鳴らさない
            if (next != tab) {
              _playTabSound();
            }
            notifier.state = next;
            if (next == HomeTab.record) {
              ref.read(homeViewModelProvider.notifier).refreshFiles();
            } else if (next == HomeTab.note) {
              ref.read(recordingsReloadTickProvider.notifier).state++;
            }
          },
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.tabs,
    required this.current,
    required this.onTap,
  });

  final List<HomeTab> tabs;
  final HomeTab current;
  final void Function(HomeTab) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double highlightSize = 70.0;
          const double buttonSize = 64.0;
          final itemWidth = constraints.maxWidth / tabs.length;
          final currentIndex = tabs.indexOf(current);
          final highlightLeft =
              itemWidth * currentIndex + (itemWidth - highlightSize) / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutQuad,
                left: highlightLeft,
                top: (96 - highlightSize) / 2,
                width: highlightSize,
                height: highlightSize,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final t in tabs)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(t),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: buttonSize,
                              height: buttonSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: current == t
                                    ? Colors.white.withValues(alpha: 0.26)
                                    : Colors.white.withValues(alpha: 0.14),
                                border: current == t
                                    ? null
                                    : Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                              ),
                              child: Icon(
                                t.icon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            // const SizedBox(height: 6),
                            // AnimatedDefaultTextStyle(
                            //   duration: const Duration(milliseconds: 180),
                            //   style: TextStyle(
                            //     fontSize: 12,
                            //     fontWeight: FontWeight.w600,
                            //     color: Colors.white.withOpacity(
                            //       current == t ? 0.95 : 0.75,
                            //     ),
                            //   ),
                            //   child: Text(t.name),
                            // ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeTabPage extends ConsumerWidget {
  const _HomeTabPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.read(authRepositoryProvider);
    final isAnonymous = authRepo.currentUser?.isAnonymous ?? false;

    return _GradientPage(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ホーム',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              // 匿名ユーザー向けのアカウント登録促進
              if (isAnonymous) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
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
                        '記録を安全に保存するため、アカウント登録がおすすめです。登録しておくと、ログイン状態が保たれ、あとから続きも簡単に使えます。',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
              // TODO: ユーザーの保存回数や単語数などを表示
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Text(
                      '統計情報',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '準備中...',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteTabPage extends StatelessWidget {
  const _NoteTabPage();

  @override
  Widget build(BuildContext context) {
    return _GradientPage(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  const Text(
                    '記録',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: RecordingsList()),
            // ボトムナビゲーションのスペースを確保
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }
}

class _AccountTabPage extends ConsumerWidget {
  const _AccountTabPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(userPlanProvider);
    final limitsAsync = ref.watch(userPlanLimitsProvider);
    final monthlyCountAsync = ref.watch(monthlyRecordingCountProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final isAnonymous = authRepo.currentUser?.isAnonymous ?? false;

    return _GradientPage(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'アカウント',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
                      data: (plan) => _PlanCard(
                        plan: plan,
                        limits: limitsAsync,
                        monthlyCount: monthlyCountAsync.when(
                          data: (count) => count,
                          loading: () => 0,
                          error: (_, __) => 0,
                        ),
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
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
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
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
          _PlanInfoRow(
            label: '最大録音時間',
            value: _formatDuration(limits.maxRecordingDuration),
          ),
          const SizedBox(height: 12),
          _PlanInfoRow(
            label: '月間録音回数',
            value: '$monthlyCount / ${limits.monthlyRecordingLimit}',
          ),
          const SizedBox(height: 12),
          _PlanInfoRow(
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
    return '${minutes}分';
  }
}

class _PlanInfoRow extends StatelessWidget {
  const _PlanInfoRow({
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

class _GradientPage extends StatelessWidget {
  const _GradientPage({required this.child});

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
