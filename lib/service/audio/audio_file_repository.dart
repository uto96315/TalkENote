import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AudioFileRepository {
  Future<List<FileSystemEntity>> fetchAudioFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = await dir.list().toList(); // 非同期で取得しUIブロックを防ぐ

    return files.where((f) => f.path.endsWith('.m4a')).toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // 新しい順
  }

  Future<void> deleteAllRecordings() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = await dir.list().toList();
    for (final f in files) {
      if (f.path.endsWith('.m4a')) {
        await f.delete();
      }
    }
  }
}
