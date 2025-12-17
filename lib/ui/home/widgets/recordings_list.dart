import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../constants/upload_status.dart';
import '../../../data/model/recording.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/recording_provider.dart';
import '../recording_detail_page.dart';

class RecordingsList extends ConsumerStatefulWidget {
  const RecordingsList({super.key});

  @override
  ConsumerState<RecordingsList> createState() => _RecordingsListState();
}

class _RecordingsListState extends ConsumerState<RecordingsList> {
  late final AudioPlayer _player;
  String? _playingId;
  bool _isLoading = false;
  List<Recording> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(recordingRepositoryProvider);
    final auth = ref.read(authRepositoryProvider);
    final user = auth.currentUser;
    if (user == null) {
      setState(() {
        _items = [];
        _error = 'サインインしていません';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await repo.fetchRecordingsByUser(user.uid);
      setState(() {
        _items = items;
      });
    } catch (e) {
      setState(() {
        _error = '読み込みに失敗しました: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _play(Recording rec) async {
    final repo = ref.read(recordingRepositoryProvider);
    try {
      final url = await repo.downloadUrl(rec.storagePath);
      await _player.setUrl(url);
      await _player.play();
      setState(() => _playingId = rec.id);
    } catch (e) {
      setState(() => _error = '再生できませんでした: $e');
    }
  }

  Future<void> _reupload(Recording rec) async {
    final repo = ref.read(recordingRepositoryProvider);
    setState(() => _isLoading = true);
    try {
      final exists = await repo.existsInStorage(rec.storagePath);
      if (!exists) {
        setState(() => _error = '元ファイルが見つかりませんでした');
      } else {
        await repo.reuploadFromStorage(
          recordingId: rec.id,
          storagePath: rec.storagePath,
        );
        await _load();
      }
    } catch (e) {
      setState(() => _error = '再アップロードに失敗しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            if (!_isLoading && _items.isEmpty && _error == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('まだ記録がありません'),
              ),
            if (_items.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final rec = _items[i];
                    final created = rec.createdAt?.toDate();
                    final dateLabel = created != null
                        ? '${created.year}/${created.month.toString().padLeft(2, '0')}/${created.day.toString().padLeft(2, '0')} ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}'
                        : '';
                    final isPlaying = _playingId == rec.id;
                    final isPending = rec.uploadStatus == UploadStatus.pending;
                    return Card(
                      child: ListTile(
                        title: Text(rec.title ?? '(タイトルなし)'),
                        subtitle: Text(dateLabel),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if ((rec.memo ?? '').isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.sticky_note_2_outlined,
                                  size: 20,
                                ),
                              ),
                            if (isPending)
                              TextButton(
                                onPressed:
                                    _isLoading ? null : () => _reupload(rec),
                                child: const Text('再アップロード'),
                              ),
                            IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_arrow,
                              ),
                              onPressed: () async {
                                if (isPlaying) {
                                  await _player.stop();
                                  setState(() => _playingId = null);
                                } else {
                                  await _play(rec);
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecordingDetailPage(recording: rec),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

