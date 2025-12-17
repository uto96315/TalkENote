import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talkenote/service/audio/audio_file_repository.dart';
import 'package:talkenote/service/audio/record_audio_service.dart';

import '../../constants/app_colors.dart';
import '../../constants/home_tab.dart';

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
        children: const [
          _HomeTabPage(),
          _NoteTabPage(),
          _AccountTabPage(),
        ],
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

class _HomeTabPage extends StatefulWidget {
  const _HomeTabPage();

  @override
  State<_HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<_HomeTabPage> {
  final audioService = RecordAudioService();
  bool isRecording = false;
  final repo = AudioFileRepository();
  final player = AudioPlayer();

  List<FileSystemEntity> files = [];
  String? playingPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await repo.fetchAudioFiles();
    setState(() => files = result);
  }

  Future<void> _play(String path) async {
    if (playingPath == path) {
      await player.stop();
      setState(() => playingPath = null);
      return;
    }

    await player.setFilePath(path);
    await player.play();
    setState(() => playingPath = path);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(
            height: 200,
          ),
          ElevatedButton(
            onPressed: () async {
              debugPrint("tapped");
              if (isRecording) {
                final path = await audioService.stop();
                debugPrint('saved: $path');
                if (path != null) {
                  await _load(); // 新規録音を反映
                }
              } else {
                await audioService.start();
              }
              setState(() {
                isRecording = !isRecording;
                if (!isRecording) {
                  playingPath = null; // 録音終了時は再生状態をリセット
                }
              });
            },
            child: Text(isRecording ? 'Stop' : 'Record'),
          ),
          if (files.isEmpty) const Text(""),
          if (files.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: files.length,
                itemBuilder: (_, i) {
                  final file = files[i];
                  final name = file.path.split('/').last;
                  final isPlaying = playingPath == file.path;

                  return ListTile(
                    leading: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                    title: Text(name),
                    onTap: () => _play(file.path),
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
