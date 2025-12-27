import 'dart:async';
import 'dart:io';

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/transcript_status.dart';
import '../constants/user_plan.dart';
import '../service/audio/audio_file_repository.dart';
import '../service/audio/record_audio_service.dart';
import '../service/ai/transcription_service.dart';
import '../service/ai/sentence_splitter_service.dart';
import '../service/ai/translation_suggestion_service.dart';
import '../service/notification_service.dart';
import '../data/repository/recording_repository.dart';
import '../data/repository/auth_repository.dart';
import '../data/repository/user_repository.dart';
import '../provider/ai_provider.dart';
import '../provider/auth_provider.dart';
import '../provider/plan_provider.dart';
import '../provider/recording_provider.dart';
import '../provider/user_provider.dart';
import '../provider/ad_provider.dart';
import '../constants/upload_status.dart';
import '../data/model/sentence.dart';

class HomeState {
  const HomeState({
    this.files = const [],
    this.isRecording = false,
    this.isLoading = false,
    this.recordingElapsed = Duration.zero,
    this.errorMessage,
    this.progressMessage,
    this.completedRecordingId,
  });

  final List<FileSystemEntity> files;
  final bool isRecording;
  final bool isLoading;
  final Duration recordingElapsed;
  final String? errorMessage;
  final String? progressMessage; // 処理進捗メッセージ
  final String? completedRecordingId; // 処理完了した録音ID

  HomeState copyWith({
    List<FileSystemEntity>? files,
    bool? isRecording,
    bool? isLoading,
    Duration? recordingElapsed,
    String? errorMessage,
    String? progressMessage,
    String? completedRecordingId,
    bool clearProgressMessage = false,
    bool clearCompletedRecordingId = false,
  }) {
    return HomeState(
      files: files ?? this.files,
      isRecording: isRecording ?? this.isRecording,
      isLoading: isLoading ?? this.isLoading,
      recordingElapsed: recordingElapsed ?? this.recordingElapsed,
      errorMessage: errorMessage ?? this.errorMessage,
      progressMessage: clearProgressMessage
          ? null
          : (progressMessage ?? this.progressMessage),
      completedRecordingId: clearCompletedRecordingId
          ? null
          : (completedRecordingId ?? this.completedRecordingId),
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
  late final UserRepository _userRepo;
  late final TranscriptionService _transcription;
  late final SentenceSplitterService _splitter;
  late final TranslationSuggestionService _translator;
  final _soundPlayer = AudioPlayer();
  bool _isLoadingFiles = false;
  Timer? _autoStopTimer;
  Timer? _elapsedTimer;
  DateTime? _recordingStartedAt;
  UserPlan? _currentPlan;

  @override
  HomeState build() {
    _recordingRepo = ref.read(recordingRepositoryProvider);
    _authRepo = ref.read(authRepositoryProvider);
    _userRepo = ref.read(userRepositoryProvider);
    _transcription = ref.read(transcriptionServiceProvider);
    _splitter = ref.read(sentenceSplitterServiceProvider);
    _translator = ref.read(translationSuggestionServiceProvider);
    ref.onDispose(() {
      _autoStopTimer?.cancel();
      _elapsedTimer?.cancel();
      _soundPlayer.dispose();
    });
    Future.microtask(() async {
      await _loadUserPlan();
      _loadFiles();
    }); // 非同期に初回ロードを開始
    return const HomeState(isLoading: true);
  }

  /// ユーザーのプランを読み込む
  Future<void> _loadUserPlan() async {
    final user = _authRepo.currentUser;
    if (user != null) {
      _currentPlan = await _userRepo.getUserPlan(user.uid);
    } else {
      _currentPlan = UserPlan.free; // デフォルトは無課金
    }
  }

  /// プランに応じた最大録音時間を取得
  Duration _getMaxRecordingDuration() {
    if (_currentPlan == null) {
      return PlanLimits.forPlan(UserPlan.free).maxRecordingDuration;
    }
    return PlanLimits.forPlan(_currentPlan!).maxRecordingDuration;
  }

  Future<void> toggleRecording() async {
    if (state.isRecording) {
      await _stopRecording();
      return;
    }

    // プラン制限をチェック
    final user = _authRepo.currentUser;
    if (user == null) {
      state = state.copyWith(
        errorMessage: 'ログインが必要です',
      );
      return;
    }

    // プランが読み込まれていない場合は読み込む
    if (_currentPlan == null) {
      await _loadUserPlan();
    }

    // 月間録音回数をチェック
    final monthlyCount = await _userRepo.getMonthlyRecordingCount(user.uid);
    final limits = PlanLimits.forPlan(_currentPlan ?? UserPlan.free);
    if (monthlyCount >= limits.monthlyRecordingLimit) {
      state = state.copyWith(
        errorMessage:
            '今月の録音回数上限（${limits.monthlyRecordingLimit}回）に達しています。プランをアップグレードしてください。',
      );
      return;
    }

    await _recordService.start();
    _playSound('click');
    _recordingStartedAt = DateTime.now();
    state = state.copyWith(
      isRecording: true,
      recordingElapsed: Duration.zero,
      errorMessage: null,
    );
    _scheduleAutoStop();
    _startElapsedTicker();
    
    // 録音中に広告を事前に読み込んでおく（無課金ユーザーのみ）
    try {
      final limits = PlanLimits.forPlan(_currentPlan ?? UserPlan.free);
      if (limits.showAds) {
        final adService = ref.read(adServiceProvider);
        // 広告が準備できていない場合は読み込む
        if (!adService.isInterstitialAdReady) {
          adService.preloadInterstitialAd();
        }
      }
    } catch (e) {
      debugPrint('Failed to preload interstitial ad: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!state.isRecording) return;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _recordingStartedAt = null;
    String? path;
    try {
      path = await _recordService.stop();
    } catch (e, s) {
      debugPrint('Failed to stop recording: $e $s');
    }

    Duration? duration;
    if (path != null) {
      duration = await _measureDuration(path);
      if (duration != null && duration < const Duration(seconds: 5)) {
        state = state.copyWith(
          isRecording: false,
          recordingElapsed: Duration.zero,
          errorMessage: '5秒未満の録音は保存できません',
        );
        try {
          await File(path).delete();
        } catch (_) {}
        return;
      }
    }

    state = state.copyWith(
      isRecording: false,
      recordingElapsed: Duration.zero,
      errorMessage: null,
    );
    _playSound('alert');
    if (path != null) {
      await _loadFiles();
      await _uploadRecording(path);
    }
  }

  void _scheduleAutoStop() {
    _autoStopTimer?.cancel();
    final maxDuration = _getMaxRecordingDuration();
    _autoStopTimer = Timer(maxDuration, () {
      _stopRecording();
    });
  }

  void _startElapsedTicker() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final started = _recordingStartedAt;
      if (!state.isRecording || started == null) return;
      final elapsed = DateTime.now().difference(started);
      state = state.copyWith(recordingElapsed: elapsed);
    });
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

      // 月間録音回数をインクリメント
      final newCount = await _userRepo.incrementMonthlyRecordingCount(user.uid);
      if (newCount == -1) {
        debugPrint(
            '⚠️Failed to increment monthly recording count, but continuing with recording save');
      }

      // プロバイダーをリフレッシュしてUIを更新
      ref.invalidate(monthlyRecordingCountProvider);

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

  Future<void> refreshFiles() async {
    await _loadFiles();
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  void clearCompletedRecording() {
    state = state.copyWith(
      clearProgressMessage: true,
      clearCompletedRecordingId: true,
    );
  }

  Future<void> _playSound(String type) async {
    try {
      // 録音中でも確実に鳴るように、just_audio でアセット音声を再生
      final assetPath = type == 'click'
          ? 'assets/sounds/rec_start.mp3'
          : type == 'alert'
              ? 'assets/sounds/rec_stop.mp3'
              : 'assets/sounds/rec_complete.mp3';
      await _soundPlayer.setAsset(assetPath);
      await _soundPlayer.play();
    } catch (e) {
      debugPrint('Failed to play sound: $e');
      // 音声ファイルがない場合やエラーが発生しても、アプリの動作は続行
      // フォールバックとして SystemSound を試す
      try {
        if (type == 'click') {
          SystemSound.play(SystemSoundType.click);
        } else if (type == 'alert') {
          SystemSound.play(SystemSoundType.alert);
        } else if (type == 'complete') {
          SystemSound.play(SystemSoundType.alert);
        }
      } catch (_) {
        // SystemSound も失敗した場合は無視
      }
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
      state = state.copyWith(progressMessage: '文字起こしを開始しています...');
      await _recordingRepo.updateTranscriptStatus(
        recordingId: recordingId,
        status: TranscriptStatus.transcribing,
      );
      print('Pipeline: status -> transcribing');

      state = state.copyWith(progressMessage: '音声を文字に変換しています...');
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

      state = state.copyWith(progressMessage: '文章を整理しています...');
      final sentencesText = await _splitter.splitSentences(text);
      sentences =
          sentencesText.map((t) => Sentence.withGeneratedId(t)).toList();
      await _recordingRepo.updateSentences(
        recordingId: recordingId,
        sentences: sentences,
      );
      print('Pipeline: sentences saved count=${sentences.length}');

      // ここでtextを保持して翻訳処理で使用
      final transcriptText = text;

      if (!_translator.isConfigured) {
        print('Pipeline: translator not configured, skip translation');
        return;
      }

      // ステップ1: 全体テキストを自然な日本語に翻訳（文脈を考慮）
      state = state.copyWith(progressMessage: '翻訳しています...');
      print('Pipeline: starting full text translation');
      final fullTranslation =
          await _translator.translateFullText(transcriptText);
      print(
          'Pipeline: full translation done, ja length=${fullTranslation.ja.length}, words=${fullTranslation.words.length}');

      // ステップ2: 全体翻訳をセンテンスに分割（日本語側も分割）
      // 簡易的に全体翻訳をセンテンス数で分割するか、AIに分割してもらう
      // ここでは、各センテンスに対して詳細化を行う
      state = state.copyWith(progressMessage: '翻訳を調整しています...');
      final translated = <Sentence>[];
      for (var i = 0; i < sentences.length; i++) {
        final s = sentences[i];
        state = state.copyWith(
            progressMessage: '翻訳を調整しています... (${i + 1}/${sentences.length})');
        // センテンスごとの詳細化（翻訳、文法ポイント、ジャンル、セグメントなど）
        final res = await _translator.generateSuggestions(
          s.text,
          genreHint: s.genre,
          allowedSegments: kAllowedSegments,
        );

        translated.add(
          s.copyWith(
            ja: res.ja,
            en: res.en,
            grammarPoint: res.grammarPoint,
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

      // ステップ3: 全体から抽出された単語・熟語情報を保存
      if (fullTranslation.words.isNotEmpty) {
        await _recordingRepo.updateWordsAndGrammar(
          recordingId: recordingId,
          words: fullTranslation.words,
          grammar: const [], // 文法解説は削除
        );
        print(
            'Pipeline: words and idioms saved: words=${fullTranslation.words.length}');
      }
    } catch (e, s) {
      debugPrint('Transcription pipeline failed: $e $s');
      try {
        await _recordingRepo.updateTranscriptStatus(
          recordingId: recordingId,
          status: TranscriptStatus.failed,
        );
      } catch (_) {}
    } finally {
      // 処理完了した録音IDを設定（正常終了時のみ）
      if (sentences.isNotEmpty) {
        _playSound('complete');
        state = state.copyWith(
          progressMessage: null,
          completedRecordingId: recordingId,
        );
        print('Pipeline: completed recordingId=$recordingId');

        // インタースティシャル広告を表示（無課金ユーザーのみ）
        try {
          // プランが読み込まれていない場合は読み込む
          if (_currentPlan == null) {
            await _loadUserPlan();
          }
          final limits = PlanLimits.forPlan(_currentPlan ?? UserPlan.free);
          debugPrint('Plan: ${_currentPlan ?? UserPlan.free}, showAds: ${limits.showAds}');
          if (limits.showAds) {
            final adService = ref.read(adServiceProvider);
            final shown = await adService.showInterstitialAd();
            debugPrint('Interstitial ad show result: $shown');
          } else {
            debugPrint('Skipping ad display (user is not on free plan)');
          }
        } catch (e) {
          debugPrint('Failed to show interstitial ad: $e');
        }

        // 通知を表示（録音IDをpayloadとして含める）
        try {
          await NotificationService().showRecordingCompletedNotification(
            recordingId: recordingId,
          );
        } catch (e) {
          debugPrint('Failed to show notification: $e');
        }
      } else {
        // エラー時は進捗メッセージのみクリア
        state = state.copyWith(progressMessage: null);
      }
      print('Pipeline: progress message cleared');
    }
  }
}
