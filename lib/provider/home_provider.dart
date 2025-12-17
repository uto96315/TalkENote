import 'dart:io';
import 'dart:typed_data';

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/transcript_status.dart';
import '../service/audio/audio_file_repository.dart';
import '../service/audio/record_audio_service.dart';
import '../service/ai/transcription_service.dart';
import '../service/ai/sentence_splitter_service.dart';
import '../service/ai/translation_suggestion_service.dart';
import '../data/repository/recording_repository.dart';
import '../data/repository/auth_repository.dart';
import '../provider/ai_provider.dart';
import '../provider/auth_provider.dart';
import '../provider/recording_provider.dart';
import '../constants/upload_status.dart';
import '../data/model/sentence.dart';

class HomeState {
  const HomeState({
    this.files = const [],
    this.isRecording = false,
    this.isLoading = false,
  });

  final List<FileSystemEntity> files;
  final bool isRecording;
  final bool isLoading;

  HomeState copyWith({
    List<FileSystemEntity>? files,
    bool? isRecording,
    bool? isLoading,
  }) {
    return HomeState(
      files: files ?? this.files,
      isRecording: isRecording ?? this.isRecording,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final homeViewModelProvider =
    AutoDisposeNotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

class HomeViewModel extends AutoDisposeNotifier<HomeState> {
  HomeViewModel() : super();

  final _audioRepo = AudioFileRepository();
  final _recordService = RecordAudioService();
  late final RecordingRepository _recordingRepo;
  late final AuthRepository _authRepo;
  late final TranscriptionService _transcription;
  late final SentenceSplitterService _splitter;
  late final TranslationSuggestionService _translator;
  bool _isLoadingFiles = false;

  @override
  HomeState build() {
    _recordingRepo = ref.read(recordingRepositoryProvider);
    _authRepo = ref.read(authRepositoryProvider);
    _transcription = ref.read(transcriptionServiceProvider);
    _splitter = ref.read(sentenceSplitterServiceProvider);
    _translator = ref.read(translationSuggestionServiceProvider);
    Future.microtask(_loadFiles); // 非同期に初回ロードを開始
    return const HomeState(isLoading: true);
  }

  Future<void> toggleRecording() async {
    if (state.isRecording) {
      final path = await _recordService.stop();
      state = state.copyWith(isRecording: false);
      if (path != null) {
        await _loadFiles();
        await _uploadRecording(path);
      }
      return;
    }

    await _recordService.start();
    state = state.copyWith(isRecording: true);
  }

  Future<void> _loadFiles() async {
    if (_isLoadingFiles) return; // 重複ロードを防ぐ
    _isLoadingFiles = true;
    state = state.copyWith(isLoading: true);
    try {
      final files = await _audioRepo.fetchAudioFiles();
      state = state.copyWith(files: files);
    } catch (e, s) {
      debugPrint('Failed to load audio files: $e $s');
    } finally {
      _isLoadingFiles = false;
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _uploadRecording(String path) async {
    final user = _authRepo.currentUser;
    if (user == null) {
      debugPrint('No user found. Skip upload.');
      return;
    }

    state = state.copyWith(isLoading: true);
    final recordingId = _recordingRepo.newRecordingId();
    try {
      final duration = await _measureDuration(path);
      final now = DateTime.now();
      final defaultTitle =
          '${now.year}/${_pad2(now.month)}/${_pad2(now.day)} ${_pad2(now.hour)}:${_pad2(now.minute)}';
      await _recordingRepo.saveMetadata(
        recordingId: recordingId,
        userId: user.uid,
        durationSec: duration == null ? 0 : duration.inMilliseconds / 1000.0,
        memo: '',
        title: defaultTitle,
        newWords: const [],
        status: UploadStatus.uploaded,
      );

      // 音声バイトを渡して同期的にパイプラインを実行
      final Uint8List bytes = await File(path).readAsBytes();
      final fileName = path.split('/').last;
      await _runTranscriptionPipeline(
        recordingId: recordingId,
        bytes: bytes,
        fileName: fileName,
      );

      try {
        await File(path).delete(); // 音声処理後はローカルを削除
      } catch (e) {
        debugPrint('Failed to delete local file: $e');
      }
    } catch (e, s) {
      debugPrint('Failed to process recording: $e $s');
      try {
        await _recordingRepo.updateStatus(
          recordingId: recordingId,
          status: UploadStatus.failed,
        );
      } catch (_) {}
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  String _pad2(int v) => v.toString().padLeft(2, '0');

  Future<Duration?> _measureDuration(String path) async {
    final tmpPlayer = AudioPlayer();
    try {
      final dur = await tmpPlayer.setFilePath(path);
      return dur ?? tmpPlayer.duration;
    } catch (e, s) {
      debugPrint('Failed to measure duration: $e $s');
      return null;
    } finally {
      await tmpPlayer.dispose();
    }
  }

  Future<void> deleteLocalRecordings() async {
    state = state.copyWith(isLoading: true);
    try {
      await _audioRepo.deleteAllRecordings();
      await _loadFiles();
    } catch (e, s) {
      debugPrint('Failed to delete local recordings: $e $s');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _runTranscriptionPipeline({
    required String recordingId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    // If API key is not configured, skip silently (manual button remains)
    if (!_transcription.isConfigured || !_splitter.isConfigured) {
      debugPrint('Transcription pipeline skipped: API key not configured');
      return;
    }

    print('Pipeline: start recordingId=$recordingId');
    List<Sentence> sentences = const [];
    try {
      await _recordingRepo.updateTranscriptStatus(
        recordingId: recordingId,
        status: TranscriptStatus.transcribing,
      );
      print('Pipeline: status -> transcribing');

      print('Pipeline: read local file $fileName (${bytes.length} bytes)');
      final text = await _transcription.transcribeFromBytes(
        bytes,
        fileName: fileName,
      );
      print('Pipeline: transcription done, length=${text.length}');

      await _recordingRepo.updateTranscriptRaw(
        recordingId: recordingId,
        transcriptRaw: text,
      );
      print('Pipeline: transcriptRaw saved (status -> done via repo)');

      final sentencesText = await _splitter.splitSentences(text);
      sentences =
          sentencesText.map((t) => Sentence.withGeneratedId(t)).toList();
      await _recordingRepo.updateSentences(
        recordingId: recordingId,
        sentences: sentences,
      );
      print('Pipeline: sentences saved count=${sentences.length}');
    } catch (e, s) {
      debugPrint('Transcription pipeline failed: $e $s');
      try {
        await _recordingRepo.updateTranscriptStatus(
          recordingId: recordingId,
          status: TranscriptStatus.failed,
        );
      } catch (_) {}
      return;
    }

    if (!_translator.isConfigured) {
      print('Pipeline: translator not configured, skip translation');
      return;
    }

    try {
      final translated = <Sentence>[];
      for (final s in sentences) {
        final res = await _translator.generateSuggestions(
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
        translated.add(
          s.copyWith(
            ja: res.ja,
            suggestions: res.suggestions,
            selected: selectedSentences,
            genre: res.genre ?? s.genre,
            segment: res.segment ?? s.segment,
          ),
        );
      }
      await _recordingRepo.updateSentences(
        recordingId: recordingId,
        sentences: translated,
      );
      print(
          'Pipeline: translation suggestions saved count=${translated.length}');
    } catch (e, s) {
      debugPrint('Translation phase failed (skipped): $e $s');
    }
  }
}
