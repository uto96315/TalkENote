import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class TranscriptionService {
  TranscriptionService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String? apiKey;
  final http.Client _client;

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  Future<String> transcribeFromUrl(
    String url, {
    String fileName = 'audio.m4a',
  }) async {
    if (!isConfigured) {
      throw StateError('OpenAI API key is not configured');
    }
    final res = await _client.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to download audio. status=${res.statusCode}');
    }
    return transcribeFromBytes(res.bodyBytes, fileName: fileName);
  }

  Future<String> transcribeFromBytes(
    Uint8List bytes, {
    String fileName = 'audio.m4a',
  }) async {
    if (!isConfigured) {
      throw StateError('OpenAI API key is not configured');
    }

    final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = 'whisper-1'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode != 200) {
      throw Exception('Transcription failed: ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final text = data['text'] as String? ?? '';
    return text.trim();
  }
}
