import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../constants/home_tab.dart';
import '../../provider/home_provider.dart';
import '../../provider/plan_provider.dart';
import '../../provider/recording_provider.dart';
import '../../provider/ad_provider.dart';
import 'pages/account_tab_page.dart';
import 'pages/home_tab_page.dart';
import 'pages/note_tab_page.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/home_tab.dart' show RecordTabPage;

final currentTabProvider = StateProvider<HomeTab>((ref) => HomeTab.home);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _tabSoundPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // ホーム画面表示時に広告を事前読み込み（無課金ユーザーのみ）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAdsIfNeeded();
    });
  }

  void _preloadAdsIfNeeded() {
    final shouldShowAds = ref.read(shouldShowAdsProvider);
    if (shouldShowAds) {
      final adService = ref.read(adServiceProvider);
      adService.preloadInterstitialAd();
    }
  }

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
          HomeTabPage(),
          RecordTabPage(),
          NoteTabPage(),
          AccountTabPage(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FloatingNavBar(
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
