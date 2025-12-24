import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TranscriptionService {
  TranscriptionService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String? apiKey;
  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 30);

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  Future<String> transcribeFromUrl(
    String url, {
    String fileName = 'audio.m4a',
  }) async {
    if (!isConfigured) {
      throw StateError('OpenAI API key is not configured');
    }
    try {
      final res = await _client
          .get(Uri.parse(url))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timeout: Failed to download audio');
      });
      if (res.statusCode != 200) {
        throw Exception('Failed to download audio. status=${res.statusCode}');
      }
      return transcribeFromBytes(res.bodyBytes, fileName: fileName);
    } on SocketException catch (e) {
      debugPrint('Network error: $e');
      throw Exception(
          'Network error: Unable to connect. Please check your internet connection.');
    } on TimeoutException catch (e) {
      debugPrint('Timeout error: $e');
      throw Exception('Request timeout: Please try again.');
    } on HttpException catch (e) {
      debugPrint('HTTP error: $e');
      throw Exception('HTTP error: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      rethrow;
    }
  }

  Future<String> transcribeFromBytes(
    Uint8List bytes, {
    String fileName = 'audio.m4a',
  }) async {
    if (!isConfigured) {
      throw StateError('OpenAI API key is not configured');
    }

    try {
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

      final streamed = await req.send().timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timeout: Transcription request timed out');
      });
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode != 200) {
        throw Exception('Transcription failed: ${resp.body}');
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final text = data['text'] as String? ?? '';
      return text.trim();
    } on SocketException catch (e) {
      debugPrint('Network error: $e');
      throw Exception(
          'Network error: Unable to connect. Please check your internet connection.');
    } on TimeoutException catch (e) {
      debugPrint('Timeout error: $e');
      throw Exception('Request timeout: Please try again.');
    } on HttpException catch (e) {
      debugPrint('HTTP error: $e');
      throw Exception('HTTP error: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      rethrow;
    }
  }
}
