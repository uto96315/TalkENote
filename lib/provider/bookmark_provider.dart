import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

/// 単語がブックマークされているか確認するProvider
final isWordBookmarkedProvider =
    FutureProvider.family<bool, WordBookmarkKey>((ref, key) async {
  final authRepo = ref.read(authRepositoryProvider);
  final userRepo = ref.read(userRepositoryProvider);
  final user = authRepo.currentUser;

  if (user == null) {
    return false;
  }

  return await userRepo.isWordBookmarked(
    uid: user.uid,
    word: key.word,
    ja: key.ja,
  );
});

/// ブックマーク状態を管理するためのキー
class WordBookmarkKey {
  const WordBookmarkKey({
    required this.word,
    required this.ja,
  });

  final String word;
  final String ja;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordBookmarkKey &&
          runtimeType == other.runtimeType &&
          word == other.word &&
          ja == other.ja;

  @override
  int get hashCode => word.hashCode ^ ja.hashCode;
}

