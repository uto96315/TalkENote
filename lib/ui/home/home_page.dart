import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/home_tab.dart';
import '../../provider/home_provider.dart';
import '../../provider/recording_provider.dart';
import 'widgets/home_tab.dart';
import 'widgets/recordings_list.dart';

final currentTabProvider = StateProvider<HomeTab>((ref) => HomeTab.home);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

class _AccountTabPage extends StatelessWidget {
  const _AccountTabPage();

  @override
  Widget build(BuildContext context) {
    return const _GradientPage(
      child: SafeArea(
        child: Center(
          child: Text('アカウントページ（準備中）'),
        ),
      ),
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
