import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _isLoading = false;
  List<Recording> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
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
                    return Card(
                      child: ListTile(
                        title: Text(rec.title ?? '(タイトルなし)'),
                        subtitle: Text(dateLabel),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecordingDetailPage(recording: rec),
                            ),
                          );
                          await _load();
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

