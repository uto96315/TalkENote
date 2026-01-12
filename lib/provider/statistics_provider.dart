import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'recording_provider.dart';
import 'user_provider.dart';

/// 統計情報モデル
class StatisticsData {
  const StatisticsData({
    required this.recordingCount,
    required this.bookmarkedWordsCount,
    required this.bookmarkedIdiomsCount,
  });

  final int recordingCount;
  final int bookmarkedWordsCount;
  final int bookmarkedIdiomsCount;
}

/// 統計情報を取得するProvider
final statisticsProvider =
    FutureProvider.autoDispose<StatisticsData>((ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final user = authRepo.currentUser;

  if (user == null) {
    return const StatisticsData(
      recordingCount: 0,
      bookmarkedWordsCount: 0,
      bookmarkedIdiomsCount: 0,
    );
  }

  final recordingRepo = ref.read(recordingRepositoryProvider);
  final userRepo = ref.read(userRepositoryProvider);

  final results = await Future.wait([
    recordingRepo.getRecordingCount(user.uid),
    userRepo.getBookmarkedWordsCount(user.uid),
    userRepo.getBookmarkedIdiomsCount(user.uid),
  ]);

  return StatisticsData(
    recordingCount: results[0],
    bookmarkedWordsCount: results[1],
    bookmarkedIdiomsCount: results[2],
  );
});

