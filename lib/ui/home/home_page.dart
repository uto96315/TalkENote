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
      body: IndexedStack(
        index: tabs.indexOf(tab),
        children: const [HomeTabPage(), _NoteTabPage(), _AccountTabPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabs.indexOf(tab),
        selectedItemColor: AppColors.primary,
        onTap: (index) {
          final next = tabs[index];
          notifier.state = next;
          if (next == HomeTab.home) {
            ref.read(homeViewModelProvider.notifier).refreshFiles();
          } else if (next == HomeTab.note) {
            ref.read(recordingsReloadTickProvider.notifier).state++;
          }
        },
        items: [
          for (final t in tabs)
            BottomNavigationBarItem(
              icon: Icon(t.icon),
              label: t.name,
            ),
        ],
      ),
    );
  }
}

class _NoteTabPage extends StatelessWidget {
  const _NoteTabPage();

  @override
  Widget build(BuildContext context) => const RecordingsList();
}

class _AccountTabPage extends StatelessWidget {
  const _AccountTabPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('アカウントページ（準備中）'),
    );
  }
}
