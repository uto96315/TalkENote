import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/home_tab.dart';

final currentTabProvider = StateProvider<HomeTab>((ref) => HomeTab.home);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(currentTabProvider);
    final notifier = ref.read(currentTabProvider.notifier);

    return Scaffold(
      body: _buildBody(tab),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: HomeTab.values.indexOf(tab),
        selectedItemColor: AppColors.primary,
        onTap: (index) => notifier.state = HomeTab.values[index],
        items: [
          for (final t in HomeTab.values)
            BottomNavigationBarItem(
              icon: Icon(t.icon),
              label: t.name,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(HomeTab tab) {
    switch (tab) {
      case HomeTab.home:
        return const _PlaceholderPage(title: 'ホーム');
      case HomeTab.note:
        return const _PlaceholderPage(title: '記録');
      case HomeTab.account:
        return const _PlaceholderPage(title: 'アカウント');
    }
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
