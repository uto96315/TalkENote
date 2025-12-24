// ignore_for_file: avoid_print

import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkenote/constants/app_colors.dart';

import '../../data/model/recording.dart';
import '../../data/model/sentence.dart';
import '../../provider/ai_provider.dart';
import '../../service/ai/translation_suggestion_service.dart';
import '../../provider/recording_provider.dart';
import '../../constants/transcript_status.dart';
import '../../utils/snackbar_utils.dart';

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
  final bool _saving = false;
  bool _splitting = false;
  bool _translating = false;
  bool _isEditingTitle = false;
  bool _isEditingMemo = false;

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
    final created = recording.createdAt?.toDate();
    final dateLabel = created != null
        ? '${created.year}/${created.month.toString().padLeft(2, '0')}/${created.day.toString().padLeft(2, '0')} '
            '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}'
        : '-';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          // テキストフィールド外をタップしたら編集を終了
          if (_isEditingTitle) {
            setState(() => _isEditingTitle = false);
            _saveTitle();
          }
          if (_isEditingMemo) {
            setState(() => _isEditingMemo = false);
            _saveMemo();
          }
          // キーボードを閉じる
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),
                      _isEditingTitle
                          ? GestureDetector(
                              onTap: () {}, // テキストフィールド内のタップは無視
                              child: TextField(
                                controller: _titleCtrl,
                                autofocus: true,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'タイトル',
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (_) {
                                  setState(() => _isEditingTitle = false);
                                  _saveTitle();
                                },
                              ),
                            )
                          : InkWell(
                              onTap: () {
                                setState(() => _isEditingTitle = true);
                              },
                              child: _row(
                                  'タイトル',
                                  _titleCtrl.text.isEmpty
                                      ? '-'
                                      : _titleCtrl.text),
                            ),
                      const SizedBox(height: 12),
                      _row('作成日時', dateLabel),
                      const SizedBox(height: 12),
                      _isEditingMemo
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {}, // テキストフィールド内のタップは無視
                                  child: TextField(
                                    controller: _memoCtrl,
                                    autofocus: true,
                                    minLines: 3,
                                    maxLines: 5,
                                    textInputAction: TextInputAction.newline,
                                    decoration: const InputDecoration(
                                      labelText: 'メモ',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() => _isEditingMemo = false);
                                      _saveMemo();
                                      FocusScope.of(context).unfocus();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('完了'),
                                  ),
                                ),
                              ],
                            )
                          : InkWell(
                              onTap: () {
                                setState(() => _isEditingMemo = true);
                              },
                              child: _row(
                                  'メモ',
                                  _memoCtrl.text.isEmpty
                                      ? '-'
                                      : _memoCtrl.text),
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
                      // Text(
                      //   '文字起こしと分割',
                      //   style: Theme.of(context).textTheme.titleMedium,
                      // ),
                      // const SizedBox(height: 8),
                      // Wrap(
                      //   spacing: 12,
                      //   runSpacing: 8,
                      //   children: [
                      //     ElevatedButton.icon(
                      //       icon: _recording.transcriptStatus ==
                      //               TranscriptStatus.transcribing
                      //           ? const SizedBox(
                      //               width: 16,
                      //               height: 16,
                      //               child: CircularProgressIndicator(
                      //                   strokeWidth: 2),
                      //             )
                      //           : const Icon(Icons.translate),
                      //       label: const Text('文字起こしする'),
                      //       onPressed: _recording.transcriptStatus ==
                      //               TranscriptStatus.transcribing
                      //           ? null
                      //           : () {
                      //               debugPrint("tapped");
                      //               _onTranscribe();
                      //             },
                      //     ),
                      //     ElevatedButton.icon(
                      //       icon: _splitting
                      //           ? const SizedBox(
                      //               width: 16,
                      //               height: 16,
                      //               child: CircularProgressIndicator(
                      //                   strokeWidth: 2),
                      //             )
                      //           : const Icon(Icons.format_list_bulleted),
                      //       label: const Text('文に分割'),
                      //       onPressed: _splitting ? null : _onSplitSentences,
                      //     ),
                      //     ElevatedButton.icon(
                      //       icon: _translating
                      //           ? const SizedBox(
                      //               width: 16,
                      //               height: 16,
                      //               child: CircularProgressIndicator(
                      //                   strokeWidth: 2),
                      //             )
                      //           : const Icon(Icons.g_translate),
                      //       label: const Text('翻訳候補を生成'),
                      //       onPressed:
                      //           _translating ? null : _onGenerateTranslations,
                      //     ),
                      //   ],
                      // ),
                      // const SizedBox(height: 12),
                      _TranscriptCard(text: recording.transcriptRaw),
                      const SizedBox(height: 16),
                      _SentencesSection(
                        sentences: recording.sentences,
                        onEdit: _editSentence,
                        recordingId: _recording.id,
                        onUpdate: (updated) {
                          setState(() {
                            _recording = updated;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 50,
                    width: 50,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(1000),
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTitle() async {
    final repo = ref.read(recordingRepositoryProvider);
    try {
      await repo.updateInfo(
        recordingId: _recording.id,
        title: _titleCtrl.text.trim(),
      );
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.show(context, '保存に失敗しました: $e');
      }
    }
  }

  Future<void> _saveMemo() async {
    final repo = ref.read(recordingRepositoryProvider);
    try {
      await repo.updateInfo(
        recordingId: _recording.id,
        memo: _memoCtrl.text,
      );
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.show(context, '保存に失敗しました: $e');
      }
    }
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
    final repo = ref.read(recordingRepositoryProvider);
    final transcription = ref.read(transcriptionServiceProvider);
    if (!transcription.isConfigured) {
      SnackBarUtils.show(context, 'OpenAI APIキーが設定されていません (.env)');
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
      SnackBarUtils.show(context, '文字起こしが完了しました');
    } catch (e) {
      _log('Transcribe 🎙️: failed ❌ $e');
      await repo.updateTranscriptStatus(
        recordingId: _recording.id,
        status: TranscriptStatus.failed,
      );
      SnackBarUtils.show(context, '文字起こしに失敗しました: $e');
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
    final splitter = ref.read(sentenceSplitterServiceProvider);
    final repo = ref.read(recordingRepositoryProvider);
    final raw = _recording.transcriptRaw?.trim() ?? '';

    if (raw.isEmpty) {
      SnackBarUtils.show(context, '先に文字起こしを実行してください');
      return;
    }
    if (!splitter.isConfigured) {
      SnackBarUtils.show(context, 'OpenAI APIキーが設定されていません (.env)');
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
      SnackBarUtils.show(context, '文分割が完了しました');
    } catch (e) {
      _log('Split ✂️: failed ❌ $e');
      SnackBarUtils.show(context, '文分割に失敗しました: $e');
    } finally {
      if (mounted) setState(() => _splitting = false);
    }
  }

  Future<void> _editSentence(Sentence sentence) async {
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
      SnackBarUtils.show(context, '空の文は保存できません');
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
      SnackBarUtils.show(context, '更新しました');
    } catch (e) {
      SnackBarUtils.show(context, '更新に失敗しました: $e');
    }
  }

  Future<void> _onGenerateTranslations() async {
    final translator = ref.read(translationSuggestionServiceProvider);
    final repo = ref.read(recordingRepositoryProvider);

    if (!translator.isConfigured) {
      SnackBarUtils.show(context, 'OpenAI APIキーが設定されていません (.env)');
      return;
    }
    if (_recording.sentences.isEmpty) {
      SnackBarUtils.show(context, '先に文分割を実行してください');
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
      SnackBarUtils.show(context, '翻訳候補を生成しました');
    } catch (e) {
      SnackBarUtils.show(context, '翻訳候補の生成に失敗しました: $e');
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
    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '会話全文',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (value.isEmpty)
              Text(
                'まだ文字起こしされていません',
                style:
                    theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
              )
            else
              SelectableText(value),
          ],
        ),
      ),
    );
  }
}

class _SentencesSection extends ConsumerWidget {
  const _SentencesSection({
    required this.sentences,
    required this.onEdit,
    required this.recordingId,
    required this.onUpdate,
  });

  final List<Sentence> sentences;
  final void Function(Sentence sentence) onEdit;
  final String recordingId;
  final void Function(Recording) onUpdate;

  Future<void> _toggleSuggestionSelection(
    WidgetRef ref,
    BuildContext context,
    Sentence sentence,
    String suggestionText,
  ) async {
    final repo = ref.read(recordingRepositoryProvider);

    // selectedには1つしか入らないため、既に選択されている場合は解除、
    // されていない場合は既存の選択をクリアして新しい選択肢を設定
    final currentSelected = List<String>.from(sentence.selected);
    final isCurrentlySelected = currentSelected.contains(suggestionText);

    final newSelected = isCurrentlySelected
        ? <String>[] // 既に選択されている場合は解除
        : <String>[suggestionText]; // 新しい選択肢を設定（既存の選択はクリア）

    final updatedSentence = sentence.copyWith(selected: newSelected);
    final newSentences = sentences
        .map((s) => s.id == sentence.id ? updatedSentence : s)
        .toList();

    try {
      await repo.updateSentences(
        recordingId: recordingId,
        sentences: newSentences,
      );
      // 親ウィジェットに更新を通知
      final updatedRecording = await repo.fetchRecordingById(recordingId);
      if (updatedRecording != null) {
        onUpdate(updatedRecording);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    }
  }

  void _showDescPopup(BuildContext context, String desc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('説明'),
          content: Text(desc),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'センテンスごとの翻訳候補',
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
                    title: Text(s.text,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // if ((s.ja ?? '').isNotEmpty)
                        //   Padding(
                        //     padding: const EdgeInsets.only(top: 4),
                        //     child: Text(
                        //       s.ja!,
                        //       style: const TextStyle(color: Colors.black87),
                        //     ),
                        //   ),
                        if (s.suggestions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: s.suggestions.map((suggestion) {
                                final sentence = suggestion['en'] ?? '';
                                final desc = suggestion['desc'] ?? '';
                                final isSelected =
                                    s.selected.contains(sentence);
                                return InkWell(
                                  onTap: () => _toggleSuggestionSelection(
                                      ref, context, s, sentence),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      color: isSelected
                                          ? Colors.blue.shade50
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            sentence,
                                            softWrap: true,
                                          ),
                                        ),
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () =>
                                                _showDescPopup(context, desc),
                                            child: Icon(
                                              Icons.info_outline,
                                              size: 18,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
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
                                fontSize: 15,
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
