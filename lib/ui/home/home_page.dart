import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../constants/app_colors.dart';
import '../../constants/home_tab.dart';
import '../../constants/user_plan.dart';
import '../../provider/home_provider.dart';
import '../../provider/plan_provider.dart';
import '../../provider/recording_provider.dart';
import 'widgets/home_tab.dart';
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
        children: const [HomeTabPage(), _NoteTabPage(), _AccountTabPage()],
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
            if (next == HomeTab.home) {
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

class _NoteTabPage extends StatelessWidget {
  const _NoteTabPage();

  @override
  Widget build(BuildContext context) {
    return const _GradientPage(
      child: SafeArea(child: RecordingsList()),
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

    return _GradientPage(
      child: SafeArea(
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
        color: Colors.white.withOpacity(0.2),
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
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  plan.displayName,
                  style: const TextStyle(
                    fontSize: 14,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('プランアップグレード機能は準備中です'),
                  ),
                );
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
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
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
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.homeGradient,
      ),
      child: child,
    );
  }
}
