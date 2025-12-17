// ignore_for_file: avoid_print

import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/upload_status.dart';
import '../../data/model/recording.dart';
import '../../data/model/sentence.dart';
import '../../provider/ai_provider.dart';
import '../../service/ai/translation_suggestion_service.dart';
import '../../provider/recording_provider.dart';
import '../../constants/transcript_status.dart';

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
  late Recording _recording;
  bool _saving = false;
  bool _splitting = false;
  bool _translating = false;

  @override
  void initState() {
    super.initState();
    _recording = widget.recording;
    _log('DetailPage init for recordingId=${_recording.id}');
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
    final recording = _recording;
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
              const SizedBox(height: 24),
              Text(
                '文字起こしと分割',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    icon: _recording.transcriptStatus ==
                            TranscriptStatus.transcribing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.translate),
                    label: const Text('文字起こしする'),
                    onPressed: _recording.transcriptStatus ==
                            TranscriptStatus.transcribing
                        ? null
                        : () {
                            debugPrint("tapped");
                            _onTranscribe();
                          },
                  ),
                  ElevatedButton.icon(
                    icon: _splitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.format_list_bulleted),
                    label: const Text('文に分割'),
                    onPressed: _splitting ? null : _onSplitSentences,
                  ),
                  ElevatedButton.icon(
                    icon: _translating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.g_translate),
                    label: const Text('翻訳候補を生成'),
                    onPressed: _translating ? null : _onGenerateTranslations,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TranscriptCard(text: recording.transcriptRaw),
              const SizedBox(height: 16),
              _SentencesSection(
                sentences: recording.sentences,
                onEdit: _editSentence,
              ),
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

  Future<void> _onTranscribe() async {
    final scaffold = ScaffoldMessenger.of(context);
    final repo = ref.read(recordingRepositoryProvider);
    final transcription = ref.read(transcriptionServiceProvider);
    if (!transcription.isConfigured) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('OpenAI APIキーが設定されていません (.env)')),
      );
      return;
    }
    _log('Transcribe 🎙️: start (id=${_recording.id})');
    debugPrint('Transcribe 🎙️: start (id=${_recording.id})');
    setState(() {
      _recording = _recording.copyWith(
        transcriptStatus: TranscriptStatus.transcribing,
      );
    });
    _log('Transcribe 🎙️: status -> transcribing (local)');
    await repo.updateTranscriptStatus(
      recordingId: _recording.id,
      status: TranscriptStatus.transcribing,
    );
    _log('Transcribe 🎙️: status -> transcribing (remote)');
    var success = false;
    try {
      final url = await repo.downloadUrl(_recording.storagePath);
      final fileName = _recording.storagePath.split('/').last;
      _log('Transcribe 🎙️: download URL ready for $fileName');
      final text =
          await transcription.transcribeFromUrl(url, fileName: fileName);
      _log('Transcribe 🎙️: whisper done ✅ saving text (${text.length} chars)');
      await repo.updateTranscriptRaw(
        recordingId: _recording.id,
        transcriptRaw: text,
      );
      _log('Transcribe 🎙️: transcriptRaw saved to Firestore');
      setState(() {
        _recording = _recording.copyWith(
          transcriptRaw: text,
          sentences: const [],
          transcriptStatus: TranscriptStatus.done,
        );
      });
      _log('Transcribe 🎙️: state -> done ✅ (local)');
      success = true;
      scaffold.showSnackBar(
        const SnackBar(content: Text('文字起こしが完了しました')),
      );
    } catch (e) {
      _log('Transcribe 🎙️: failed ❌ $e');
      await repo.updateTranscriptStatus(
        recordingId: _recording.id,
        status: TranscriptStatus.failed,
      );
      scaffold.showSnackBar(
        SnackBar(content: Text('文字起こしに失敗しました: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _recording = _recording.copyWith(
            transcriptStatus:
                success ? TranscriptStatus.done : TranscriptStatus.failed,
          );
        });
      }
    }
  }

  Future<void> _onSplitSentences() async {
    final scaffold = ScaffoldMessenger.of(context);
    final splitter = ref.read(sentenceSplitterServiceProvider);
    final repo = ref.read(recordingRepositoryProvider);
    final raw = _recording.transcriptRaw?.trim() ?? '';

    if (raw.isEmpty) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('先に文字起こしを実行してください')),
      );
      return;
    }
    if (!splitter.isConfigured) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('OpenAI APIキーが設定されていません (.env)')),
      );
      return;
    }
    _log('Split ✂️: start (id=${_recording.id})');
    setState(() => _splitting = true);
    try {
      final sentencesText = await splitter.splitSentences(raw);
      _log('Split ✂️: AI returned ${sentencesText.length} sentences');
      final sentences =
          sentencesText.map((t) => Sentence.withGeneratedId(t)).toList();
      await repo.updateSentences(
        recordingId: _recording.id,
        sentences: sentences,
      );
      _log('Split ✂️: sentences saved to Firestore');
      setState(() {
        _recording = _recording.copyWith(sentences: sentences);
      });
      _log('Split ✂️: state updated ✅');
      scaffold.showSnackBar(
        const SnackBar(content: Text('文分割が完了しました')),
      );
    } catch (e) {
      _log('Split ✂️: failed ❌ $e');
      scaffold.showSnackBar(
        SnackBar(content: Text('文分割に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _splitting = false);
    }
  }

  Future<void> _editSentence(Sentence sentence) async {
    final scaffold = ScaffoldMessenger.of(context);
    final repo = ref.read(recordingRepositoryProvider);
    final ctrl = TextEditingController(text: sentence.text);
    String? updatedText;
    try {
      updatedText = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('文を編集'),
            content: TextField(
              controller: ctrl,
              minLines: 1,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    } finally {
      ctrl.dispose();
    }
    if (updatedText == null) return;
    if (updatedText.isEmpty) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('空の文は保存できません')),
      );
      return;
    }

    final newSentences = _recording.sentences
        .map(
          (s) => s.id == sentence.id ? s.copyWith(text: updatedText) : s,
        )
        .toList();
    try {
      await repo.updateSentences(
        recordingId: _recording.id,
        sentences: newSentences,
      );
      setState(() {
        _recording = _recording.copyWith(sentences: newSentences);
      });
      scaffold.showSnackBar(
        const SnackBar(content: Text('更新しました')),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    }
  }

  Future<void> _onGenerateTranslations() async {
    final scaffold = ScaffoldMessenger.of(context);
    final translator = ref.read(translationSuggestionServiceProvider);
    final repo = ref.read(recordingRepositoryProvider);

    if (!translator.isConfigured) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('OpenAI APIキーが設定されていません (.env)')),
      );
      return;
    }
    if (_recording.sentences.isEmpty) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('先に文分割を実行してください')),
      );
      return;
    }

    setState(() => _translating = true);
    try {
      final updated = <Sentence>[];
      for (final s in _recording.sentences) {
        final res = await translator.generateSuggestions(
          s.text,
          genreHint: s.genre,
          allowedSegments: kAllowedSegments,
        );
        final selectedSentences = res.selected.isNotEmpty
            ? res.selected
            : res.suggestions
                .map((m) => m['en'])
                .whereType<String>()
                .where((e) => e.isNotEmpty)
                .toList();
        updated.add(
          s.copyWith(
            ja: res.ja,
            suggestions: res.suggestions,
            selected: selectedSentences,
            genre: res.genre ?? s.genre,
            segment: res.segment ?? s.segment,
          ),
        );
      }
      await repo.updateSentences(
        recordingId: _recording.id,
        sentences: updated,
      );
      setState(() {
        _recording = _recording.copyWith(sentences: updated);
      });
      scaffold.showSnackBar(
        const SnackBar(content: Text('翻訳候補を生成しました')),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text('翻訳候補の生成に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }
}

void _log(String message) {
  print(message); // keep stdout
  dev.log(message,
      name: 'RecordingDetailPage'); // ensure OS log (Xcode/console)
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = text?.trim() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '全文テキスト',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (value.isEmpty)
              Text(
                'まだ文字起こしされていません',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor),
              )
            else
              SelectableText(value),
          ],
        ),
      ),
    );
  }
}

class _SentencesSection extends StatelessWidget {
  const _SentencesSection({
    required this.sentences,
    required this.onEdit,
  });

  final List<Sentence> sentences;
  final void Function(Sentence sentence) onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '文リスト（編集可）',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (sentences.isEmpty)
              Text(
                'まだ分割されていません。「文に分割」を押してください。',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sentences.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = sentences[i];
                  return ListTile(
                    title: Text(s.text),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((s.ja ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              s.ja!,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        if (s.suggestions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: s.suggestions.map((suggestion) {
                                final sentence = suggestion['en'] ?? '';
                                final desc = suggestion['desc'] ?? '';
                                final isSelected =
                                    s.selected.contains(sentence);
                                return Chip(
                                  label: Text(
                                    desc.isEmpty
                                        ? sentence
                                        : '$sentence ($desc)',
                                  ),
                                  backgroundColor:
                                      isSelected ? Colors.blue.shade50 : null,
                                );
                              }).toList(),
                            ),
                          ),
                        if ((s.genre ?? '').isNotEmpty ||
                            (s.segment ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              [
                                if ((s.genre ?? '').isNotEmpty)
                                  'genre: ${s.genre}',
                                if ((s.segment ?? '').isNotEmpty)
                                  'segment: ${s.segment}',
                              ].join(' / '),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
