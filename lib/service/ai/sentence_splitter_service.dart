import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SentenceSplitterService {
  SentenceSplitterService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String? apiKey;
  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 30);

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  Future<List<String>> splitSentences(String transcriptRaw) async {
    if (!isConfigured) {
      throw StateError('OpenAI API key is not configured');
    }
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final body = {
      'model': 'gpt-4o-mini',
      'temperature': 0,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a helpful assistant that splits English transcripts into natural sentences. '
                  'Return only a JSON array of strings.'
        },
        {
          'role': 'user',
          'content':
              'Split the following text into sentences. Return ONLY a JSON array of strings. '
                  'Text:\n$transcriptRaw'
        }
      ],
    };

    try {
      final resp = await _client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timeout: Sentence split request timed out');
      });
      if (resp.statusCode != 200) {
        throw Exception('Sentence split failed: ${resp.body}');
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>? ?? [];
      if (choices.isEmpty) {
        throw Exception('No choices returned from splitter');
      }
      final content = (choices.first['message']
              as Map<String, dynamic>?)?['content'] as String? ??
          '';
      return _extractSentences(content);
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

  List<String> _extractSentences(String rawContent) {
    final trimmed = rawContent.trim();
    final start = trimmed.indexOf('[');
    final end = trimmed.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) {
      throw FormatException('Response did not contain a JSON array.');
    }
    final jsonArray = trimmed.substring(start, end + 1);
    final decoded = jsonDecode(jsonArray);
    if (decoded is! List) {
      throw FormatException('Response was not a JSON array.');
    }
    return decoded
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
}
