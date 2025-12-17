import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AudioFileRepository {
  Future<List<FileSystemEntity>> fetchAudioFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();

    return files.where((f) => f.path.endsWith('.m4a')).toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // 新しい順
  }
}
