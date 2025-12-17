import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/home_tab.dart';
import '../../provider/home_provider.dart';

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
        children: const [_HomeTabPage(), _NoteTabPage(), _AccountTabPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabs.indexOf(tab),
        selectedItemColor: AppColors.primary,
        onTap: (index) => notifier.state = tabs[index],
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

class _HomeTabPage extends ConsumerWidget {
  const _HomeTabPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final vm = ref.read(homeViewModelProvider.notifier);

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 200),
          ElevatedButton(
            onPressed: () => vm.toggleRecording(),
            child: Text(state.isRecording ? 'Stop' : 'Record'),
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          if (!state.isLoading && state.files.isEmpty) const Text(""),
          if (state.files.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: state.files.length,
                itemBuilder: (_, i) {
                  final file = state.files[i];
                  final name = file.path.split('/').last;
                  final isPlaying = state.playingPath == file.path;

                  return ListTile(
                    leading: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                    title: Text(name),
                    onTap: () => vm.togglePlay(file.path),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NoteTabPage extends StatelessWidget {
  const _NoteTabPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('記録ページ（準備中）'),
    );
  }
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
