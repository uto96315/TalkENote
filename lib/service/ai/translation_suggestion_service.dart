import 'dart:convert';

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

class TranslationSuggestionResult {
  TranslationSuggestionResult({
    required this.ja,
    required this.suggestions,
    required this.selected,
    this.genre,
    this.segment,
  });

  final String ja;
  final List<Map<String, String>> suggestions; // [{en, desc}]
  final List<String> selected;
  final String? genre;
  final String? segment;
}

class TranslationSuggestionService {
  TranslationSuggestionService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String? apiKey;
  final http.Client _client;

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

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
          'content': 'You are a concise translator and phrasal rewriter for English learning. '
              'Given an English sentence, return JSON with keys: '
              '- ja: natural Japanese rendering capturing nuance '
              '- suggestions: array of objects [{ "en": "...", "desc": "..." }], desc is a brief JP note '
              '- selected: array of one or more "en" strings chosen from suggestions '
              '- genre: short snake_case genre key (e.g., acknowledgement_agreement) '
              '- segment: $segmentConstraint '
              'Keep sentences concise (<=5 words) and descriptions brief.'
        },
        {
          'role': 'user',
          'content':
              'Sentence: "$sourceText"\nGenre hint: ${genreHint ?? 'none'}\nReturn JSON with keys: ja, suggestions, selected, genre, segment. '
                  'suggestions length should be $suggestionCount. selected should be a subset of the "en" values in suggestions.',
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
    final selected = (parsed['selected'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final genre = parsed['genre']?.toString();
    var segment = parsed['segment']?.toString();
    if (segment == null ||
        segment.isEmpty ||
        !effectiveAllowedSegments.contains(segment)) {
      segment = 'other'; // 許可リスト外は other にフォールバック
    }
    return TranslationSuggestionResult(
      ja: ja,
      suggestions: suggestions,
      selected: selected,
      genre: genre,
      segment: segment,
    );
  }
}
