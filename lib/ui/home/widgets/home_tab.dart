import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../provider/home_provider.dart';

class HomeTabPage extends ConsumerWidget {
  const HomeTabPage({super.key});

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(homeViewModelProvider, (prev, next) {
      final msg = next.errorMessage;
      if (msg != null && msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        ref.read(homeViewModelProvider.notifier).clearError();
      }
    });

    final state = ref.watch(homeViewModelProvider);
    final vm = ref.read(homeViewModelProvider.notifier);
    final isRecording = state.isRecording;
    final elapsedText = _formatElapsed(state.recordingElapsed);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.homeGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              'TalkENote',
              style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              isRecording ? 'レコーディング中' : 'ボタンをタップで録音開始',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            const SizedBox(height: 50),
            _RecordButton(
              isRecording: isRecording,
              onTap: () => vm.toggleRecording(),
            ),
            const SizedBox(height: 24),
            Text(
              elapsedText,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              isRecording ? 'Auto stop at 01:00' : 'Auto stop after 01:00',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.isRecording,
    required this.onTap,
  });

  final bool isRecording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
                  color: baseColor.withOpacity(isRecording ? 0.45 : 0.3),
                  blurRadius: isRecording ? 30 : 18,
                  spreadRadius: isRecording ? 8 : 4,
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
              color: isRecording ? Colors.white : baseColor,
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 48,
                color: isRecording ? baseColor : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
