import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_service.dart';

class RecordAudioService implements AudioService {
  final _record = AudioRecorder();

  @override
  Future<void> start() async {
    final hasPermission = await _record.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _record.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
      ),
      path: path,
    );
  }

  @override
  Future<String?> stop() async {
    return await _record.stop();
  }
}
