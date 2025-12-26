import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/navigator_key.dart';
import '../provider/auth_provider.dart';
import '../provider/recording_provider.dart';
import '../ui/home/recording_detail_page.dart';

/// ローカル通知サービス
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  ProviderContainer? _container;

  /// 通知サービスを初期化
  /// [container] はRiverpodのProviderContainer。通知タップ時にナビゲーションするために必要
  Future<void> initialize({ProviderContainer? container}) async {
    if (_initialized) return;
    _container = container;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (initialized ?? false) {
      _initialized = true;
      debugPrint('✅Notification service initialized');
    } else {
      debugPrint('🚨Failed to initialize notification service');
    }
  }

  /// 通知がタップされたときのハンドラー
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    
    final recordingId = response.payload;
    if (recordingId == null || recordingId.isEmpty) {
      debugPrint('No recording ID in notification payload');
      return;
    }

    // ナビゲーション処理を非同期で実行
    _navigateToRecordingDetail(recordingId);
  }

  /// 録音詳細画面へ遷移
  Future<void> _navigateToRecordingDetail(String recordingId) async {
    final container = _container;
    if (container == null) {
      debugPrint('ProviderContainer not available, cannot navigate');
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator not available, cannot navigate');
      return;
    }

    try {
      // 認証チェック
      final authRepo = container.read(authRepositoryProvider);
      final user = authRepo.currentUser;
      if (user == null) {
        debugPrint('User not authenticated, cannot navigate');
        return;
      }

      // 録音データを取得
      final recordingRepo = container.read(recordingRepositoryProvider);
      final recording = await recordingRepo.fetchRecordingById(recordingId);
      
      if (recording == null) {
        debugPrint('Recording not found: $recordingId');
        return;
      }

      // 詳細画面へ遷移
      navigator.push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RecordingDetailPage(recording: recording),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Failed to navigate to recording detail: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// 録音処理完了通知を表示
  /// [recordingId] をpayloadとして通知に含める（タップ時に詳細画面へ遷移するため）
  Future<void> showRecordingCompletedNotification({
    required String recordingId,
    String? title,
    String? body,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'recording_channel',
      '録音通知',
      channelDescription: '録音処理の完了通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'rec_complete', // カスタム通知音を設定（拡張子なし）
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      title ?? '録音処理が完了しました',
      body ?? '文字起こしと翻訳が完了しました',
      details,
      payload: recordingId, // タップ時に詳細画面へ遷移するために録音IDをpayloadに含める
    );
  }

  /// 通知をキャンセル
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

