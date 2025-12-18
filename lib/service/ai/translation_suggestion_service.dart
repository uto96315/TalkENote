import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 固定セグメント候補（ジャンル横断で利用）
const List<String> kAllowedSegments = [
  'short_ack', // 短い相槌
  'align', // 同意・歩調合わせ
  'hedge', // ぼかし・保留気味
  'defer', // 先送り・後で対応
  'repeat_check', // 繰り返し確認
  'detail_request', // 詳細を求める
  'preference', // 好み・希望を述べる
  'feedback', // 反応・フィードバック
  'info', // 事実/情報提示
  'confirmation', // 確認
  'surprise', // 驚き
  'empathy', // 共感
  'concern', // 心配・気遣い
  'regret', // 残念・後悔
  'thinking', // 思案・考え中
  'move_on', // 話題を進める
  'thanks', // 感謝
  'apology', // 謝罪
  'ask_help', // 助けを求める
  'ask_wait', // 待ってもらう
  'suggest', // 提案する
  'offer', // 提供/申し出る
  'wrap_up', // 締める・まとめ
  'light_chat', // 軽い雑談
  'other', // 該当なし/その他
];

class PhraseInfo {
  PhraseInfo({
    required this.phrase,
    required this.ja,
  });

  final String phrase; // 英語フレーズ/熟語（例: "how are you", "thank you", "I see"）
  final String ja; // 日本語訳

  Map<String, dynamic> toMap() {
    return {
      'phrase': phrase,
      'ja': ja,
    };
  }

  factory PhraseInfo.fromMap(Map<String, dynamic> map) {
    return PhraseInfo(
      phrase: map['phrase'] as String? ?? '',
      ja: map['ja'] as String? ?? '',
    );
  }
}

class TranslationSuggestionResult {
  TranslationSuggestionResult({
    required this.ja,
    required this.suggestions,
    required this.selected,
    this.genre,
    this.segment,
    List<PhraseInfo>? phrases,
  }) : phrases = phrases ?? const [];

  final String ja;
  final List<Map<String, String>> suggestions; // [{en, desc}]
  final List<String> selected;
  final String? genre;
  final String? segment;
  final List<PhraseInfo> phrases; // 抽出されたフレーズ/熟語とその日本語訳
}

// 全体翻訳用の結果
class FullTranslationResult {
  FullTranslationResult({
    required this.ja,
    List<PhraseInfo>? phrases,
  }) : phrases = phrases ?? const [];

  final String ja; // 全体の自然な日本語訳
  final List<PhraseInfo> phrases; // 全体から抽出されたフレーズ/熟語
}

class TranslationSuggestionService {
  TranslationSuggestionService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String? apiKey;
  final http.Client _client;

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  /// 全体テキストを自然な日本語に翻訳（文脈を考慮）
  Future<FullTranslationResult> translateFullText(String fullText) async {
    if (!isConfigured) {
      throw StateError('OpenAI API key is not configured');
    }
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final body = {
      'model': 'gpt-4o-mini',
      'temperature': 0.3,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': 'You are a professional translator for English learning. '
              'Translate the entire English conversation naturally into Japanese, considering context and flow. '
              'IMPORTANT: The Japanese translation should match the length and detail level of the original English text. '
              'If the English is long and detailed, the Japanese should also be long and detailed. '
              'Return JSON with keys: '
              '- ja: natural Japanese translation of the entire text, maintaining conversation flow and matching the original length/detail level '
              '- phrases: array of objects [{ "phrase": "...", "ja": "..." }] containing useful phrases, idioms, or common expressions from the entire conversation. '
              '  Extract practical phrases that are useful for learning (e.g., "how are you", "thank you", "I see", "that makes sense"). '
              '  Focus on expressions, not individual words. '
              '  Include 5-15 most useful phrases/expressions from the entire conversation.'
        },
        {
          'role': 'user',
          'content':
              'Translate this English conversation naturally into Japanese:\n\n$fullText\n\n'
                  'Return JSON with keys: ja, phrases.'
        },
      ],
    };

    final resp = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception('Full translation failed: ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      throw Exception('No choices returned for full translation');
    }
    final content = (choices.first['message']
            as Map<String, dynamic>?)?['content'] as String? ??
        '{}';
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    debugPrint('🔵 Full Translation Response:');
    debugPrint('  ja: ${parsed['ja']}');
    debugPrint('  phrases: ${parsed['phrases']}');

    final ja = parsed['ja']?.toString() ?? '';
    final phrases = (parsed['phrases'] as List<dynamic>?)
            ?.map((e) {
              if (e is Map<String, dynamic>) {
                return PhraseInfo.fromMap(e);
              }
              if (e is Map) {
                return PhraseInfo.fromMap(Map<String, dynamic>.from(e));
              }
              return null;
            })
            .whereType<PhraseInfo>()
            .toList() ??
        const [];
    debugPrint('🔵 Parsed phrases count: ${phrases.length}');
    return FullTranslationResult(
      ja: ja,
      phrases: phrases,
    );
  }

  Future<TranslationSuggestionResult> generateSuggestions(
    String sourceText, {
    String? genreHint,
    int suggestionCount = 3,
    List<String>? allowedSegments,
  }) async {
    if (!isConfigured) {
      throw StateError('OpenAI API key is not configured');
    }
    // 有効なセグメント集合に必ず 'other' を含める
    final effectiveAllowedSegments = <String>{
      ...(allowedSegments ?? const []),
      'other',
    }.toList();
    final segmentConstraint = (effectiveAllowedSegments.isNotEmpty)
        ? 'segment must be one of: ${effectiveAllowedSegments.join(', ')} (use "other" when none apply)'
        : 'segment: short snake_case subcategory (e.g., short_ack, align, hedge, other)';
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final body = {
      'model': 'gpt-4o-mini',
      'temperature': 0.2,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': 'You are a professional translator and phrasal rewriter for English learning. '
              'Given an English sentence, return JSON with keys: '
              '- ja: natural Japanese translation that matches the length and detail level of the original English sentence. '
              '  If the English is long and detailed, the Japanese must also be long and detailed. '
              '  Preserve the original meaning, nuance, and level of detail. '
              '- suggestions: array of objects [{ "en": "...", "desc": "..." }], desc is a brief JP note. '
              '  Each suggestion should be a complete, natural English sentence that conveys the same meaning. '
              '  Suggestions should match the length and detail level of the original sentence. '
              '  Use appropriate subjects (we, I, they, etc.) based on context. '
              '- selected: (OPTIONAL) array of "en" strings chosen from suggestions. If no selection should be made by default, return an empty array []. Only include translations that should be pre-selected. '
              '- genre: short snake_case genre key (e.g., acknowledgement_agreement) '
              '- segment: $segmentConstraint '
              '- phrases: array of objects [{ "phrase": "...", "ja": "..." }] containing useful phrases, idioms, or common expressions from the sentence. '
              '  Extract practical phrases (e.g., "how are you", "thank you", "I see", "that makes sense"). '
              '  Focus on expressions, not individual words. '
              '  Include 2-5 most useful phrases/expressions. '
              'IMPORTANT: Do not shorten or simplify the translation. Maintain the original sentence structure and detail level.'
        },
        {
          'role': 'user',
          'content': 'Sentence: "$sourceText"\nGenre hint: ${genreHint ?? 'none'}\nReturn JSON with keys: ja, suggestions, selected, genre, segment, phrases. '
              'suggestions length should be $suggestionCount. '
              'Each suggestion must be a complete, natural English sentence that matches the length and detail level of the original. '
              'Use appropriate subjects based on context (we, I, they, etc.). '
              'selected should be an empty array [] by default. Only include translations in selected if they should be pre-selected. '
              'The Japanese translation (ja) must also match the length and detail level of the original English sentence. '
              'phrases should contain useful phrases/expressions from the sentence with Japanese translations.',
        },
      ],
    };

    final resp = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception('Translation suggestion failed: ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      throw Exception('No choices returned for translation suggestion');
    }
    final content = (choices.first['message']
            as Map<String, dynamic>?)?['content'] as String? ??
        '{}';
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    debugPrint('🟢 Translation Suggestion Response for: "$sourceText"');
    debugPrint('  ja: ${parsed['ja']}');
    debugPrint('  suggestions: ${parsed['suggestions']}');
    debugPrint('  selected: ${parsed['selected']}');
    debugPrint('  genre: ${parsed['genre']}');
    debugPrint('  segment: ${parsed['segment']}');
    debugPrint('  phrases: ${parsed['phrases']}');

    final ja = parsed['ja']?.toString() ?? '';
    final suggestions = (parsed['suggestions'] as List<dynamic>?)
            ?.map((e) {
              if (e is Map<String, dynamic>) {
                return {
                  'en': e['en']?.toString() ?? '',
                  'desc': e['desc']?.toString() ?? '',
                };
              }
              if (e is Map) {
                final m = Map<String, dynamic>.from(e);
                return {
                  'en': m['en']?.toString() ?? '',
                  'desc': m['desc']?.toString() ?? '',
                };
              }
              return null;
            })
            .whereType<Map<String, String>>()
            .toList() ??
        const [];
    // selectedはデフォルトで空の配列（AIが返しても無視）
    final selected = const <String>[];
    final genre = parsed['genre']?.toString();
    var segment = parsed['segment']?.toString();
    if (segment == null ||
        segment.isEmpty ||
        !effectiveAllowedSegments.contains(segment)) {
      segment = 'other'; // 許可リスト外は other にフォールバック
    }
    final phrases = (parsed['phrases'] as List<dynamic>?)
            ?.map((e) {
              if (e is Map<String, dynamic>) {
                return PhraseInfo.fromMap(e);
              }
              if (e is Map) {
                return PhraseInfo.fromMap(Map<String, dynamic>.from(e));
              }
              return null;
            })
            .whereType<PhraseInfo>()
            .toList() ??
        const [];
    debugPrint('🟢 Parsed phrases count: ${phrases.length}');
    return TranslationSuggestionResult(
      ja: ja,
      suggestions: suggestions,
      selected: selected,
      genre: genre,
      segment: segment,
      phrases: phrases,
    );
  }
}
