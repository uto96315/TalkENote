import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../service/audio/audio_file_repository.dart';
import '../service/audio/record_audio_service.dart';
import '../data/repository/recording_repository.dart';
import '../data/repository/auth_repository.dart';
import '../provider/auth_provider.dart';
import '../provider/recording_provider.dart';
import '../constants/upload_status.dart';

class HomeState {
  const HomeState({
    this.files = const [],
    this.isRecording = false,
    this.playingPath,
    this.isLoading = false,
  });

  final List<FileSystemEntity> files;
  final bool isRecording;
  final String? playingPath;
  final bool isLoading;

  HomeState copyWith({
    List<FileSystemEntity>? files,
    bool? isRecording,
    String? playingPath,
    bool? isLoading,
  }) {
    return HomeState(
      files: files ?? this.files,
      isRecording: isRecording ?? this.isRecording,
      playingPath: playingPath ?? this.playingPath,
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
  late final AudioPlayer _player;
  bool _isLoadingFiles = false;

  @override
  HomeState build() {
    _recordingRepo = ref.read(recordingRepositoryProvider);
    _authRepo = ref.read(authRepositoryProvider);
    _player = AudioPlayer();
    ref.onDispose(_player.dispose);
    Future.microtask(_loadFiles); // 非同期に初回ロードを開始
    return const HomeState(isLoading: true);
  }

  Future<void> toggleRecording() async {
    if (state.isRecording) {
      final path = await _recordService.stop();
      state = state.copyWith(isRecording: false, playingPath: null);
      if (path != null) {
        await _loadFiles();
        await _uploadRecording(path);
      }
      return;
    }

    await _recordService.start();
    state = state.copyWith(isRecording: true);
  }

  Future<void> togglePlay(String path) async {
    if (state.playingPath == path) {
      await _player.stop();
      state = state.copyWith(playingPath: null);
      return;
    }

    await _player.setFilePath(path);
    await _player.play();
    state = state.copyWith(playingPath: path);
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
    final plannedStoragePath = 'recordings/${user.uid}/$recordingId.m4a';
    var metadataSaved = false;
    try {
      final duration = await _measureDuration(path);
      final now = DateTime.now();
      final defaultTitle =
          '${now.year}/${_pad2(now.month)}/${_pad2(now.day)} ${_pad2(now.hour)}:${_pad2(now.minute)}';
      await _recordingRepo.saveMetadata(
        recordingId: recordingId,
        userId: user.uid,
        storagePath: plannedStoragePath,
        durationSec: duration == null ? 0 : duration.inMilliseconds / 1000.0,
        memo: '',
        title: defaultTitle,
        newWords: const [],
        status: UploadStatus.pending,
      );
      metadataSaved = true;

      final storagePath = await _recordingRepo.uploadRecording(
        userId: user.uid,
        recordingId: recordingId,
        file: File(path),
      );
      await _recordingRepo.updateStatus(
        recordingId: recordingId,
        status: UploadStatus.uploaded,
        storagePath: storagePath,
      );

      try {
        await File(path).delete(); // アップロード成功後はローカルを削除
      } catch (e) {
        debugPrint('Failed to delete local file: $e');
      }
    } catch (e, s) {
      debugPrint('Failed to upload recording: $e $s');
      // saveMetadataが成功している場合のみステータス更新を試みる
      if (metadataSaved) {
        try {
          await _recordingRepo.updateStatus(
            recordingId: recordingId,
            status: UploadStatus.failed,
          );
        } catch (_) {}
      }
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
    state = state.copyWith(isLoading: true, playingPath: null);
    try {
      await _audioRepo.deleteAllRecordings();
      await _loadFiles();
    } catch (e, s) {
      debugPrint('Failed to delete local recordings: $e $s');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
