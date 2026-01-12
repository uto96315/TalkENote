import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import '../../../constants/app_colors.dart';
import '../../../provider/auth_provider.dart';
import '../../auth/signup_page.dart';
import '../widgets/gradient_page.dart';

class HomeTabPage extends ConsumerStatefulWidget {
  const HomeTabPage({super.key});

  @override
  ConsumerState<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends ConsumerState<HomeTabPage> {
  StateMachineController? _controller;
  SMIBool? _isBikkuriInput;
  SMIBool? _isHappyInput;
  SMIBool? _isCommentingInput;
  Timer? _resetTimer;
  bool _isBikkuri = false;
  bool _isHappy = false;
  bool _isCommenting = false;

  void _initializeInputs() {
    if (_controller == null) return;

    for (var input in _controller!.inputs) {
      if (input is SMIBool) {
        switch (input.name) {
          case 'isBikkuri':
            _isBikkuriInput = input;
            debugPrint('✅ Found isBikkuri input');
            break;
          case 'isHappy':
            _isHappyInput = input;
            debugPrint('✅ Found isHappy input');
            break;
          case 'isCommenting':
            _isCommentingInput = input;
            debugPrint('✅ Found isCommenting input');
            break;
        }
      }
    }

    // 利用可能な入力を確認
    debugPrint(
        'Available inputs: ${_controller!.inputs.map((i) => '${i.name} (${i.runtimeType})').toList()}');
  }

  void _updateInputs() {
    _isBikkuriInput?.value = _isBikkuri;
    _isHappyInput?.value = _isHappy;
    _isCommentingInput?.value = _isCommenting;
    debugPrint(
        'Updated inputs: isBikkuri=$_isBikkuri, isHappy=$_isHappy, isCommenting=$_isCommenting');
  }

  void _resetToJoy() {
    setState(() {
      _isBikkuri = false;
      _isHappy = false;
      _isCommenting = false;
    });
    _updateInputs();
    _stopResetTimer();
    debugPrint('Reset to joy state');
  }

  void _startResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _resetToJoy();
    });
  }

  void _stopResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = null;
  }

  void _testBikkuri() {
    setState(() {
      _isBikkuri = true;
      _isHappy = false;
      _isCommenting = false;
    });
    _updateInputs();
    _startResetTimer();
  }

  void _testJump() {
    setState(() {
      _isBikkuri = false;
      _isHappy = true;
      _isCommenting = false;
    });
    _updateInputs();
    _startResetTimer();
  }

  void _testComment() {
    setState(() {
      _isBikkuri = false;
      _isHappy = false;
      _isCommenting = true;
    });
    _updateInputs();
    _startResetTimer();
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.read(authRepositoryProvider);
    final isAnonymous = authRepo.currentUser?.isAnonymous ?? false;

    return GradientPage(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ホーム',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Riveアニメーション
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  color: Colors.transparent,
                  child: RiveAnimation.asset(
                    'assets/animations/test.riv',
                    fit: BoxFit.contain,
                    onInit: (artboard) {
                      try {
                        _controller = StateMachineController.fromArtboard(
                          artboard,
                          'State Machine 1',
                        );
                        if (_controller != null) {
                          artboard.addController(_controller!);
                          _initializeInputs();
                          debugPrint(
                              '✅ Rive State Machine initialized successfully');
                        } else {
                          debugPrint('⚠️ State Machine Controller not found');
                          // 利用可能なステートマシンを確認
                          debugPrint(
                              'Available state machines: ${artboard.stateMachines.map((sm) => sm.name).toList()}');
                        }
                      } catch (e, stackTrace) {
                        debugPrint('🚨 Error initializing Rive controller: $e');
                        debugPrint('Stack trace: $stackTrace');
                        // ステートマシンなしでアニメーションを表示
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // テストボタン
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _testBikkuri,
                        icon: const Icon(Icons.emoji_emotions),
                        label: const Text('bikkuri'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _testJump,
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('jump'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _testComment,
                    icon: const Icon(Icons.comment),
                    label: const Text('comment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 匿名ユーザー向けのアカウント登録促進
              if (isAnonymous) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'アカウントを登録してください',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '記録を安全に保存するため、アカウント登録がおすすめです。登録しておくと、ログイン状態が保たれ、あとから続きも簡単に使えます。',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SignUpPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'アカウントを登録',
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
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopResetTimer();
    _controller?.dispose();
    super.dispose();
  }
}
