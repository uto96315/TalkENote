import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/ad_service.dart';

/// AdServiceのProvider
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  // プロバイダーが破棄されたときにdisposeを呼ぶ
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

