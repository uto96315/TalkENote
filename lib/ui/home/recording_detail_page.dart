// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:talkenote/constants/app_colors.dart';

import '../../data/model/recording.dart';
import '../../data/model/sentence.dart';
import '../../provider/recording_provider.dart';
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
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ヘッダー
              _buildHeader(context),
              // コンテンツ
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // タイトル・メモ・日時セクション
                        _buildInfoSection(context, recording, dateLabel),
                        const SizedBox(height: 24),
                        // 文字起こし全文
                        if (recording.transcriptRaw != null &&
                            recording.transcriptRaw!.isNotEmpty) ...[
                          _TranscriptCard(text: recording.transcriptRaw),
                          const SizedBox(height: 24),
                        ],
                        // 単語・熟語セクション
                        if (recording.words.isNotEmpty) ...[
                          _buildVocabularySection(context, recording),
                          const SizedBox(height: 24),
                        ],
                        // センテンスごとの翻訳
                        if (recording.sentences.isNotEmpty)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '録音詳細',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44), // バランス調整
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, Recording recording, String dateLabel) {
    return _ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isEditingTitle
              ? TextField(
                  controller: _titleCtrl,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'タイトル',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onSubmitted: (_) {
                    setState(() => _isEditingTitle = false);
                    _saveTitle();
                  },
                )
              : InkWell(
                  onTap: () {
                    setState(() => _isEditingTitle = true);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'タイトル',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _titleCtrl.text.isEmpty
                                    ? 'タイトル未設定'
                                    : _titleCtrl.text,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _titleCtrl.text.isEmpty
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 20),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: '作成日時',
            value: dateLabel,
          ),
          const SizedBox(height: 16),
          _isEditingMemo
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _memoCtrl,
                      autofocus: true,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'メモ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _isEditingMemo = false);
                          _saveMemo();
                          FocusScope.of(context).unfocus();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('保存'),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: () {
                    setState(() => _isEditingMemo = true);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'メモ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _memoCtrl.text.isEmpty
                                    ? 'メモを追加'
                                    : _memoCtrl.text,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _memoCtrl.text.isEmpty
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildVocabularySection(BuildContext context, Recording recording) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 単語セクション
        if (recording.words.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.book_outlined,
            title: '単語',
            subtitle: '${recording.words.length}個',
          ),
          const SizedBox(height: 12),
          _ModernCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: recording.words.map((wordInfo) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: _WordChip(
                    word: wordInfo.word,
                    ja: wordInfo.ja,
                    partOfSpeech: wordInfo.partOfSpeech,
                    example: wordInfo.example,
                    exampleJa: wordInfo.exampleJa,
                    difficulty: wordInfo.difficulty,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
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

  // 将来的に使用する可能性があるためコメントアウト

  Future<void> _editSentence(Sentence sentence) async {
    final repo = ref.read(recordingRepositoryProvider);
    final ctrl = TextEditingController(text: sentence.text);
    String? updatedText;
    try {
      updatedText = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('センテンスを編集'),
            content: TextField(
              controller: ctrl,
              maxLines: 5,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(ctrl.text),
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    } finally {
      ctrl.dispose();
    }
    if (updatedText == null || updatedText == sentence.text) return;

    final updated = sentence.copyWith(text: updatedText);
    final newSentences = _recording.sentences
        .map((s) => s.id == sentence.id ? updated : s)
        .toList();
    await repo.updateSentences(
      recordingId: _recording.id,
      sentences: newSentences,
    );
    setState(() {
      _recording = _recording.copyWith(sentences: newSentences);
    });
  }
}

void _log(String message) {
  print(message);
  dev.log(message, name: 'RecordingDetailPage');
}

// モダンなカードウィジェット
class _ModernCard extends StatelessWidget {
  const _ModernCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      width: MediaQuery.of(context).size.width,
      child: child,
    );
  }
}

// セクションヘッダー
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// 情報行
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 単語チップ
class _WordChip extends StatefulWidget {
  const _WordChip({
    required this.word,
    required this.ja,
    this.partOfSpeech,
    this.example,
    this.exampleJa,
    this.difficulty,
  });

  final String word;
  final String ja;
  final String? partOfSpeech;
  final String? example;
  final String? exampleJa;
  final int? difficulty;

  @override
  State<_WordChip> createState() => _WordChipState();
}

class _WordChipState extends State<_WordChip> {
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;
  Timer? _speakTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _speakTimer?.cancel();
    _flutterTts?.stop();
    _flutterTts = null;
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      _flutterTts = FlutterTts();

      // 完了ハンドラーを最初に設定（これが重要）
      _flutterTts?.setCompletionHandler(() {
        debugPrint('TTS completion handler called');
        _speakTimer?.cancel(); // タイマーをキャンセル
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      _flutterTts?.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      // 設定を適用
      await _flutterTts?.setLanguage('en-US');
      await _flutterTts?.setSpeechRate(0.5);
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setPitch(1.0);
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  Future<void> _speak() async {
    if (_flutterTts == null) {
      await _initTts();
    }

    if (_flutterTts == null) {
      debugPrint('TTS not initialized');
      return;
    }

    try {
      // 既存のタイマーをキャンセル
      _speakTimer?.cancel();

      // 既に再生中の場合は停止
      if (_isSpeaking) {
        await _flutterTts?.stop();
        // 停止してから少し待つ
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (!mounted) return;

      setState(() {
        _isSpeaking = true;
      });

      // 読み上げを開始
      await _flutterTts?.speak(widget.word);

      // フォールバック: 完了ハンドラーが呼ばれない場合に備えて、
      // 単語の長さに基づいて推定される時間後に状態をリセット
      final estimatedDuration = Duration(
        milliseconds: widget.word.length * 100 + 500, // 文字数 * 100ms + 余裕500ms
      );

      _speakTimer = Timer(estimatedDuration, () {
        if (mounted && _isSpeaking) {
          debugPrint('TTS fallback timer: resetting _isSpeaking');
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      debugPrint('TTS speak called for: ${widget.word}');
    } catch (e) {
      debugPrint('Error speaking: $e');
      _speakTimer?.cancel();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  /// 品詞を日本語ラベルに変換
  String _getPartOfSpeechLabel(String partOfSpeech) {
    switch (partOfSpeech.toLowerCase()) {
      case 'noun':
        return '名詞';
      case 'verb':
        return '動詞';
      case 'adjective':
        return '形容詞';
      case 'adverb':
        return '副詞';
      case 'idiom':
        return 'イディオム';
      case 'phrase':
        return 'フレーズ';
      case 'preposition':
        return '前置詞';
      case 'conjunction':
        return '接続詞';
      case 'pronoun':
        return '代名詞';
      default:
        return partOfSpeech; // 不明な場合はそのまま返す
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 140,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.word,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _isSpeaking ? null : _speak,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _isSpeaking
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.volume_up,
                    size: 18,
                    color: _isSpeaking
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ),
              if (widget.partOfSpeech != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getPartOfSpeechLabel(widget.partOfSpeech!),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              if (widget.difficulty != null) ...[
                const SizedBox(width: 6),
                ...List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 12,
                    color: index < widget.difficulty!
                        ? Colors.amber
                        : Colors.grey.shade300,
                  );
                }),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.ja,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          if (widget.example != null && widget.example!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"${widget.example}"',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
            if (widget.exampleJa != null && widget.exampleJa!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '"${widget.exampleJa}"',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.text});

  final String? text;

  /// 句点で区切って改行を追加
  String _formatTextWithLineBreaks(String text) {
    // 句点（。）で分割して、各センテンスの後に改行を追加
    return text
        .split('。')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim() + '。')
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final value = text?.trim() ?? '';
    final formattedValue =
        value.isNotEmpty ? _formatTextWithLineBreaks(value) : '';

    return _ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notes_outlined,
                  size: 18,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '会話全文',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (value.isEmpty)
            Text(
              'まだ文字起こしされていません',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            SelectableText(
              formattedValue,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
        ],
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.translate,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'センテンスごとの翻訳',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sentences.isEmpty)
            Text(
              'まだ分割されていません',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sentences.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final s = sentences[i];
                return _SentenceCard(
                  sentence: s,
                  onEdit: () => onEdit(s),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SentenceCard extends StatefulWidget {
  const _SentenceCard({
    required this.sentence,
    required this.onEdit,
  });

  final Sentence sentence;
  final VoidCallback onEdit;

  @override
  State<_SentenceCard> createState() => _SentenceCardState();
}

class _SentenceCardState extends State<_SentenceCard> {
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;
  Timer? _speakTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _speakTimer?.cancel();
    _flutterTts?.stop();
    _flutterTts = null;
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      _flutterTts = FlutterTts();

      _flutterTts?.setCompletionHandler(() {
        _speakTimer?.cancel();
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      _flutterTts?.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _speakTimer?.cancel();
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      await _flutterTts?.setLanguage('en-US');
      await _flutterTts?.setSpeechRate(0.5);
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setPitch(1.0);
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  Future<void> _speak(String text) async {
    if (_flutterTts == null) {
      await _initTts();
    }

    if (_flutterTts == null) {
      debugPrint('TTS not initialized');
      return;
    }

    try {
      _speakTimer?.cancel();

      if (_isSpeaking) {
        await _flutterTts?.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (!mounted) return;

      setState(() {
        _isSpeaking = true;
      });

      await _flutterTts?.speak(text);

      // フォールバックタイマー
      final estimatedDuration = Duration(
        milliseconds: text.length * 100 + 1000, // 長文対応で余裕を持たせる
      );

      _speakTimer = Timer(estimatedDuration, () {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error speaking: $e');
      _speakTimer?.cancel();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.sentence.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (widget.sentence.en != null && widget.sentence.en!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.sentence.en!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _isSpeaking
                            ? null
                            : () => _speak(widget.sentence.en!),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _isSpeaking
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.volume_up,
                            size: 18,
                            color: _isSpeaking
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (widget.sentence.grammarPoint != null &&
              widget.sentence.grammarPoint!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.sentence.grammarPoint!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
