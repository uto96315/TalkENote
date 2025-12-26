import 'package:uuid/uuid.dart';

class Sentence {
  Sentence({
    required this.id,
    required this.text,
    this.confidence,
    this.ja,
    this.en,
    this.grammarPoint,
    this.genre,
    this.segment,
  });

  final String id;
  final String text;
  final double? confidence;
  final String? ja; // 日本語（元のテキストまたは翻訳）
  final String? en; // 英語翻訳（単一）
  final String? grammarPoint; // 文法的ポイント（例: "許可を求めるのはmay I ~?で表す"）
  final String? genre;
  final String? segment;

  factory Sentence.fromMap(Map<String, dynamic> map) {
    return Sentence(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble(),
      ja: map['ja'] as String?,
      en: map['en'] as String?,
      grammarPoint: map['grammarPoint'] as String?,
      genre: map['genre'] as String?,
      segment: map['segment'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      if (confidence != null) 'confidence': confidence,
      if (ja != null) 'ja': ja,
      if (en != null) 'en': en,
      if (grammarPoint != null) 'grammarPoint': grammarPoint,
      if (genre != null) 'genre': genre,
      if (segment != null) 'segment': segment,
    };
  }

  Sentence copyWith({
    String? id,
    String? text,
    double? confidence,
    String? ja,
    String? en,
    String? grammarPoint,
    String? genre,
    String? segment,
  }) {
    return Sentence(
      id: id ?? this.id,
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      ja: ja ?? this.ja,
      en: en ?? this.en,
      grammarPoint: grammarPoint ?? this.grammarPoint,
      genre: genre ?? this.genre,
      segment: segment ?? this.segment,
    );
  }

  static Sentence withGeneratedId(
    String text, {
    double? confidence,
    String? ja,
    String? en,
    String? grammarPoint,
    String? genre,
    String? segment,
  }) {
    return Sentence(
      id: const Uuid().v4(),
      text: text,
      confidence: confidence,
      ja: ja,
      en: en,
      grammarPoint: grammarPoint,
      genre: genre,
      segment: segment,
    );
  }
}
