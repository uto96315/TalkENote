import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../service/audio/audio_file_repository.dart';
import '../service/audio/record_audio_service.dart';

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
  late final AudioPlayer _player;
  bool _isLoading = false;

  @override
  HomeState build() {
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
    if (_isLoading) return; // 重複ロードを防ぐ
    _isLoading = true;
    state = state.copyWith(isLoading: true);
    try {
      final files = await _audioRepo.fetchAudioFiles();
      state = state.copyWith(files: files);
    } catch (e, s) {
      debugPrint('Failed to load audio files: $e $s');
    } finally {
      _isLoading = false;
      state = state.copyWith(isLoading: false);
    }
  }
}
