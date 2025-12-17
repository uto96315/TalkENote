import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/upload_status.dart';
import '../../data/model/recording.dart';
import '../../provider/recording_provider.dart';

class RecordingDetailPage extends ConsumerStatefulWidget {
  const RecordingDetailPage({super.key, required this.recording});

  final Recording recording;

  @override
  ConsumerState<RecordingDetailPage> createState() =>
      _RecordingDetailPageState();
}

class _RecordingDetailPageState extends ConsumerState<RecordingDetailPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _memoCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.recording.title ?? '');
    _memoCtrl = TextEditingController(text: widget.recording.memo ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recording = widget.recording;
    final repo = ref.read(recordingRepositoryProvider);
    final created = recording.createdAt?.toDate();
    final dateLabel = created != null
        ? '${created.year}/${created.month.toString().padLeft(2, '0')}/${created.day.toString().padLeft(2, '0')} '
            '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}'
        : '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('録音詳細'),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      await repo.updateInfo(
                        recordingId: recording.id,
                        title: _titleCtrl.text.trim(),
                        memo: _memoCtrl.text,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('保存しました')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('保存に失敗しました: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            child: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _row('作成日時', dateLabel),
              const SizedBox(height: 8),
              _row('ステータス', recording.uploadStatus.value),
              const SizedBox(height: 8),
              _row('長さ (sec)', recording.durationSec.toStringAsFixed(2)),
              const SizedBox(height: 8),
              _row('ストレージパス', recording.storagePath),
              const SizedBox(height: 12),
              TextField(
                controller: _memoCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'メモ',
                  border: OutlineInputBorder(),
                ),
              ),
              if (recording.newWords.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '新規単語',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: recording.newWords
                      .map((w) => Chip(label: Text(w)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value.isEmpty ? '-' : value),
        ),
      ],
    );
  }
}
