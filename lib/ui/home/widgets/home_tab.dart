import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/home_tab.dart';
import '../../../provider/home_provider.dart';
import '../../../provider/recording_provider.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/plan_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../home_page.dart';
import '../recording_detail_page.dart';

class RecordTabPage extends ConsumerWidget {
  const RecordTabPage({super.key});

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(homeViewModelProvider, (prev, next) {
      final prevMsg = prev?.errorMessage;
      final nextMsg = next.errorMessage;
      // エラーメッセージが新しく設定された場合のみ処理（無限ループを防ぐ）
      if (nextMsg != null && nextMsg.isNotEmpty && prevMsg != nextMsg) {
        SnackBarUtils.show(context, nextMsg);
        // エラーをクリアするのは、次のフレームで実行（無限ループを防ぐ）
        Future.microtask(() {
          ref.read(homeViewModelProvider.notifier).clearError();
        });
      }
    });

    final state = ref.watch(homeViewModelProvider);
    final vm = ref.read(homeViewModelProvider.notifier);
    final isRecording = state.isRecording;
    final elapsedText = _formatElapsed(state.recordingElapsed);
    final limits = ref.watch(userPlanLimitsProvider);
    final monthlyCountAsync = ref.watch(monthlyRecordingCountProvider);
    final maxDuration = limits.maxRecordingDuration;

    // 残り時間を計算
    Duration? remainingTime;
    if (isRecording && state.recordingElapsed < maxDuration) {
      remainingTime = maxDuration - state.recordingElapsed;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.homeGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            _RecordButton(
              isRecording: isRecording,
              text: isRecording ? 'レコーディング中' : 'タップで録音開始',
              onTap: () => vm.toggleRecording(),
            ),
            const SizedBox(height: 24),
            // 経過時間の表示
            Text(
              elapsedText,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            // プラン制限の表示
            if (isRecording && remainingTime != null) ...[
              // 録音中：残り時間を表示
              Text(
                '残り ${_formatDuration(remainingTime)} で自動停止',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: remainingTime.inSeconds <= 10
                          ? Colors.red[300]
                          : remainingTime.inSeconds <= 30
                              ? Colors.orange[300]
                              : Colors.white,
                      fontWeight: remainingTime.inSeconds <= 30
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
              ),
            ] else ...[
              // 録音停止中：最大録音時間を表示
              Text(
                '最大録音時間: ${_formatDuration(maxDuration)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            // 月間録音回数の表示
            monthlyCountAsync.when(
              data: (count) {
                final limit = limits.monthlyRecordingLimit;
                final isNearLimit = count >= limit * 0.8; // 80%以上で警告
                final isAtLimit = count >= limit;
                if (count > 0 || isNearLimit) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        Text(
                          '今月の録音: $count/$limit 回${isAtLimit ? ' (上限到達)' : isNearLimit ? ' (残り${limit - count}回)' : ''}',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: isAtLimit
                                        ? Colors.red[300]
                                        : isNearLimit
                                            ? Colors.orange[300]
                                            : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        // 上限に達した場合、プラン変更ボタンを表示
                        if (isAtLimit) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              // アカウントタブに遷移
                              ref.read(currentTabProvider.notifier).state =
                                  HomeTab.account;
                            },
                            icon: const Icon(Icons.upgrade, size: 18),
                            label: const Text('アップグレードして回数を増やす',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red[700],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (state.progressMessage != null ||
                state.completedRecordingId != null) ...[
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: state.completedRecordingId != null
                    ? _buildCompletedState(
                        context, ref, state.completedRecordingId!)
                    : _buildProgressState(state.progressMessage!),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressState(String message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedState(
    BuildContext context,
    WidgetRef ref,
    String recordingId,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text(
              '完了しました',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  ref
                      .read(homeViewModelProvider.notifier)
                      .clearCompletedRecording();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text(
                    '閉じる',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final recordingRepo = ref.read(recordingRepositoryProvider);
                  final authRepo = ref.read(authRepositoryProvider);
                  final user = authRepo.currentUser;

                  if (user == null) return;

                  // 完了した録音IDをクリア
                  ref
                      .read(homeViewModelProvider.notifier)
                      .clearCompletedRecording();

                  // 録音データを取得
                  final recording =
                      await recordingRepo.fetchRecordingById(recordingId);
                  if (recording != null && context.mounted) {
                    await Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            RecordingDetailPage(recording: recording),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
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
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text(
                    '詳細を見る',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordButton extends StatefulWidget {
  const _RecordButton({
    required this.isRecording,
    required this.onTap,
    required this.text,
  });

  final bool isRecording;
  final VoidCallback onTap;
  final String text;

  @override
  State<_RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<_RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _maybeAnimate();
  }

  @override
  void didUpdateWidget(covariant _RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRecording != widget.isRecording) {
      _maybeAnimate();
    }
  }

  void _maybeAnimate() {
    if (widget.isRecording) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.primary;
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isRecording) ...[
            _Pulse(
              controller: _controller,
              beginScale: 1.1,
              endScale: 1.8,
              beginOpacity: 0.35,
              endOpacity: 0.0,
              color: baseColor,
              delay: 0.0,
            ),
            _Pulse(
              controller: _controller,
              beginScale: 1.3,
              endScale: 2.0,
              beginOpacity: 0.28,
              endOpacity: 0.0,
              color: baseColor,
              delay: 0.3,
            ),
          ],
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  baseColor.withOpacity(0.35),
                  baseColor.withOpacity(0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(widget.isRecording ? 0.45 : 0.3),
                  blurRadius: widget.isRecording ? 30 : 18,
                  spreadRadius: widget.isRecording ? 8 : 4,
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isRecording ? Colors.white : baseColor,
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 48,
                    color: widget.isRecording ? baseColor : Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.text,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pulse extends StatelessWidget {
  const _Pulse({
    required this.controller,
    required this.beginScale,
    required this.endScale,
    required this.beginOpacity,
    required this.endOpacity,
    required this.color,
    required this.delay,
  });

  final AnimationController controller;
  final double beginScale;
  final double endScale;
  final double beginOpacity;
  final double endOpacity;
  final Color color;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, 1.0, curve: Curves.easeOut),
    );
    final scale =
        Tween<double>(begin: beginScale, end: endScale).animate(curved);
    final opacity =
        Tween<double>(begin: beginOpacity, end: endOpacity).animate(curved);

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Transform.scale(
          scale: scale.value,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(opacity.value),
            ),
          ),
        );
      },
    );
  }
}
