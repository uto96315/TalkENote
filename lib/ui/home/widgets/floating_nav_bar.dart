import 'package:flutter/material.dart';
import '../../../constants/home_tab.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
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

