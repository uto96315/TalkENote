import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkenote/constants/app_colors.dart';
import '../../../data/model/recording.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/plan_provider.dart';
import '../../../provider/recording_provider.dart';
import '../../../service/ad_service.dart';
import '../recording_detail_page.dart';

class RecordingsList extends ConsumerStatefulWidget {
  const RecordingsList({super.key});

  @override
  ConsumerState<RecordingsList> createState() => _RecordingsListState();
}

class _RecordingsListState extends ConsumerState<RecordingsList> {
  bool _isLoading = false;
  List<Recording> _items = [];
  String? _error;
  ProviderSubscription<int>? _reloadSub;

  @override
  void initState() {
    super.initState();
    // Listen for external reload requests (e.g., when switching to this tab)
    _reloadSub = ref.listenManual<int>(
      recordingsReloadTickProvider,
      (previous, next) {
        _load();
      },
    );
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(recordingRepositoryProvider);
    final auth = ref.read(authRepositoryProvider);
    final user = auth.currentUser;
    if (user == null) {
      setState(() {
        _items = [];
        _error = 'サインインしていません';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await repo.fetchRecordingsByUser(user.uid);
      setState(() {
        _items = items;
      });
    } catch (e) {
      setState(() {
        _error = '読み込みに失敗しました: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reloadSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            if (!_isLoading && _items.isEmpty && _error == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mic_none,
                        size: 64,
                        color: AppColors.white.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'まだ記録がありません',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_items.isNotEmpty)
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final shouldShowAds = ref.watch(shouldShowAdsProvider);
                    // 広告の位置も含めてカウント（有料ユーザーの場合も広告の位置はカウントするが、広告は表示しない）
                    final adCount = (_items.length / 3).ceil();
                    final totalItemCount = _items.length + adCount;
                    
                    return ListView.builder(
                      itemCount: totalItemCount,
                      itemBuilder: (_, i) {
                        // 3つに1つ広告を挿入（インデックス3, 7, 11...の位置に広告）
                        // パターン: アイテム0, 1, 2, 広告, アイテム3, 4, 5, 広告, ...
                        final positionInGroup = i % 4;
                        
                        if (positionInGroup == 3) {
                          // 広告を表示（無課金ユーザーのみ）
                          if (shouldShowAds) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: AdBanner(
                                adUnitId: AdService.getBannerAdUnitId(),
                                width: double.infinity,
                                height: 50,
                              ),
                            );
                          }
                          // 有料ユーザーの場合は広告の代わりに空のスペースを返す
                          return const SizedBox.shrink();
                        }
                    
                    // 通常のアイテムを表示
                    final groupIndex = i ~/ 4;
                    final itemIndex = groupIndex * 3 + positionInGroup;
                    
                    if (itemIndex >= _items.length) {
                      return const SizedBox.shrink();
                    }
                    
                    final rec = _items[itemIndex];
                    final created = rec.createdAt?.toDate();
                    final dateLabel = created != null
                        ? '${created.year}/${created.month.toString().padLeft(2, '0')}/${created.day.toString().padLeft(2, '0')} ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}'
                        : '';
                    return Card(
                      child: ListTile(
                        title: Text(rec.title ?? '(タイトルなし)'),
                        subtitle: Text(dateLabel),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecordingDetailPage(recording: rec),
                            ),
                          );
                          await _load();
                        },
                      ),
                    );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

}
