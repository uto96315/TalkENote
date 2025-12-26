import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

/// 単語情報
class WordInfo {
  WordInfo({
    required this.word,
    required this.ja,
    this.partOfSpeech,
    this.example,
    this.exampleJa,
    this.difficulty,
  });

  final String word; // 単語（例: "understand"）または熟語（例: "look forward to"）
  final String ja; // 日本語訳（例: "理解する"）
  final String? partOfSpeech; // 品詞（例: "verb", "noun", "adjective", "idiom"）
  final String? example; // 使用例（英語）（例: "I understand"）
  final String? exampleJa; // 使用例の日本語訳（例: "理解しています"）
  final int? difficulty; // 難易度レベル（1-5, 5が最も難しい）

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'ja': ja,
      if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
      if (example != null) 'example': example,
      if (exampleJa != null) 'exampleJa': exampleJa,
      if (difficulty != null) 'difficulty': difficulty,
    };
  }

  factory WordInfo.fromMap(Map<String, dynamic> map) {
    return WordInfo(
      word: map['word'] as String? ?? '',
      ja: map['ja'] as String? ?? '',
      partOfSpeech: map['partOfSpeech'] as String?,
      example: map['example'] as String?,
      exampleJa: map['exampleJa'] as String?,
      difficulty: (map['difficulty'] as num?)?.toInt(),
    );
  }
}

/// 文法解説情報
class GrammarInfo {
  GrammarInfo({
    required this.point,
    required this.explanation,
    this.example,
  });

  final String point; // 文法ポイント（例: "present perfect", "conditional sentences"）
  final String explanation; // 解説（例: "完了形は過去の動作が現在に影響している場合に使用"）
  final String? example; // 例文

  Map<String, dynamic> toMap() {
    return {
      'point': point,
      'explanation': explanation,
      if (example != null) 'example': example,
    };
  }

  factory GrammarInfo.fromMap(Map<String, dynamic> map) {
    return GrammarInfo(
      point: map['point'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
      example: map['example'] as String?,
    );
  }
}

class TranslationSuggestionResult {
  TranslationSuggestionResult({
    required this.ja,
    required this.en,
    this.grammarPoint,
    this.genre,
    this.segment,
  });

  final String ja; // 日本語
  final String en; // 英語翻訳（単一）
  final String? grammarPoint; // 文法的ポイント（例: "許可を求めるのはmay I ~?で表す"）
  final String? genre;
  final String? segment;
}

// 全体翻訳用の結果
class FullTranslationResult {
  FullTranslationResult({
    required this.ja,
    List<WordInfo>? words,
  }) : words = words ?? const [];

  final String ja; // 全体の自然な日本語訳
  final List<WordInfo> words; // 全体から抽出された学習価値のある単語・熟語（単語と熟語を含む）
}

class TranslationSuggestionService {
  TranslationSuggestionService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String? apiKey;
  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 30);

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  /// 基本単語リスト（除外対象）
  static const Set<String> _basicWords = {
    // 代名詞
    'i', 'you', 'he', 'she', 'it', 'we', 'they', 'this', 'that', 'these',
    'those',
    // 冠詞
    'a', 'an', 'the',
    // 基本動詞
    'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being',
    'have', 'has', 'had', 'having',
    'do', 'does', 'did', 'done', 'doing',
    'get', 'got', 'getting',
    // 前置詞
    'in', 'on', 'at', 'to', 'for', 'with', 'by', 'from', 'of', 'about', 'into',
    'onto',
    // 接続詞
    'and', 'or', 'but', 'so', 'because', 'if', 'when', 'while', 'as', 'than',
    // その他
    'not', 'no', 'yes', 'very', 'too', 'also', 'just', 'only', 'more', 'most',
    'much', 'many',
  };

  /// 基本単語かどうかをチェック
  bool _isBasicWord(String word) {
    final normalized = word.toLowerCase().trim();
    return _basicWords.contains(normalized);
  }

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
              'Given a Japanese conversation, translate it naturally into English, and extract learning materials. '
              'The user wants to learn English, so extract English vocabulary words, phrases, and grammar patterns from the translated English. '
              'Return JSON with keys: '
              '- ja: natural Japanese translation of the English translation (for reference, this should match the original Japanese text closely). '
              '  Note: Since the input is Japanese, the "ja" field should be the same as or very close to the input Japanese text. '
              '- en: natural English translation of the entire Japanese text, maintaining conversation flow and matching the original length/detail level. '
              '  This is the main translation that learners will study. '
              '- phrases: array of objects [{ "phrase": "...", "ja": "..." }] containing useful English phrases, idioms, or common expressions from the translated English conversation. '
              '  Extract practical English phrases that are useful for learning (e.g., "how are you", "thank you", "I see", "that makes sense"). '
              '  The "phrase" field should be in ENGLISH, and "ja" should be the Japanese translation. '
              '  Focus on expressions, not individual words. '
              '  Include 5-15 most useful phrases/expressions. '
              '- words: array of objects [{ "word": "...", "ja": "...", "partOfSpeech": "...", "example": "...", "exampleJa": "...", "difficulty": 1-5 }] containing useful English vocabulary words AND idioms/phrases from the translated English conversation. '
              '  The "word" field MUST be in ENGLISH - this can be a single word (e.g., "understand") OR an idiom/phrase (e.g., "look forward to", "make sense"). '
              '  The "ja" field should be the Japanese translation of the English word/phrase. '
              '  The "example" field should be an English example sentence using the English word/phrase. '
              '  The "exampleJa" field should be the Japanese translation of the example sentence. '
              '  For idioms/phrases, use partOfSpeech: "idiom" or "phrase". '
              '  EXCLUDE basic English words (I, is, the, a, an, it, that, this, and, or, but, in, on, at, to, for, with, be, have, do, get, not, very, too, etc.). '
              '  Focus on English words and idioms that are worth learning (intermediate level or above, or commonly used in daily conversation). '
              '  Include 10-20 most useful English words/idioms with Japanese translations, part of speech, English example sentences with Japanese translations, and difficulty level (1=easy, 5=difficult).'
        },
        {
          'role': 'user',
          'content': 'Translate this Japanese conversation naturally into English, and extract English learning materials:\n\n$fullText\n\n'
              'Return JSON with keys: ja, en, words. '
              'IMPORTANT: All "word" fields in the words array must be in ENGLISH (can be single words or idioms/phrases). '
              'The "exampleJa" field should be the Japanese translation of the example sentence. '
              'Include both single words and idioms/phrases in the words array.'
        },
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
        throw TimeoutException(
            'Request timeout: Full translation request timed out');
      });
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
      debugPrint('  en: ${parsed['en']}');
      debugPrint('  words: ${parsed['words']}');

      final ja = parsed['ja']?.toString() ?? '';

      // 単語・熟語をパース（基本単語を除外）
      final words = (parsed['words'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map<String, dynamic>) {
                  return WordInfo.fromMap(e);
                }
                if (e is Map) {
                  return WordInfo.fromMap(Map<String, dynamic>.from(e));
                }
                return null;
              })
              .whereType<WordInfo>()
              // クライアント側でも基本単語を除外（念のため）
              .where((word) => !_isBasicWord(word.word))
              .toList() ??
          const [];

      debugPrint('🔵 Parsed: words=${words.length}');
      return FullTranslationResult(
        ja: ja,
        words: words,
      );
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
          'content': 'You are a professional translator for English learning. '
              'Given a Japanese sentence, translate it naturally into English and provide grammatical insights. '
              'Return JSON with keys: '
              '- ja: the original Japanese sentence (for reference). '
              '- en: natural English translation that matches the length and detail level of the original Japanese sentence. '
              '  This should be a single, complete, natural English sentence. '
              '  If the Japanese is long and detailed, the English must also be long and detailed. '
              '  Preserve the original meaning, nuance, and level of detail. '
              '- grammarPoint: a brief Japanese explanation of a key English grammatical pattern or structure used in the translation. '
              '  Format: "〜を表すのは〜で表す" or "〜の場合は〜を使う" (e.g., "許可を求めるのはmay I ~?で表す", "過去の習慣を表すのはused to ~を使う"). '
              '  If no significant grammatical point exists, return an empty string "". '
              '- genre: short snake_case genre key (e.g., acknowledgement_agreement) '
              '- segment: $segmentConstraint '
              'IMPORTANT: Return only ONE English translation (en), not multiple suggestions. '
              'The grammarPoint should highlight a practical English grammar pattern that Japanese learners should understand.'
        },
        {
          'role': 'user',
          'content':
              'Japanese sentence: "$sourceText"\nGenre hint: ${genreHint ?? 'none'}\nReturn JSON with keys: ja, en, grammarPoint, genre, segment. '
                  'Provide a single English translation and a grammar point if applicable.',
        },
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
        throw TimeoutException(
            'Request timeout: Translation suggestion request timed out');
      });
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
      debugPrint('  en: ${parsed['en']}');
      debugPrint('  grammarPoint: ${parsed['grammarPoint']}');
      debugPrint('  genre: ${parsed['genre']}');
      debugPrint('  segment: ${parsed['segment']}');

      final ja = parsed['ja']?.toString() ?? '';
      final en = parsed['en']?.toString() ?? '';
      final grammarPoint = parsed['grammarPoint']?.toString();
      final genre = parsed['genre']?.toString();
      var segment = parsed['segment']?.toString();
      if (segment == null ||
          segment.isEmpty ||
          !effectiveAllowedSegments.contains(segment)) {
        segment = 'other'; // 許可リスト外は other にフォールバック
      }

      return TranslationSuggestionResult(
        ja: ja,
        en: en,
        grammarPoint: grammarPoint?.isNotEmpty == true ? grammarPoint : null,
        genre: genre,
        segment: segment,
      );
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
