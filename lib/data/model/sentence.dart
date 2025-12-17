import 'package:uuid/uuid.dart';

class Sentence {
  Sentence({
    required this.id,
    required this.text,
    this.confidence,
    this.ja,
    List<Map<String, String>>? suggestions,
    List<String>? selected,
    this.genre,
    this.segment,
  })  : suggestions = suggestions ?? const [],
        selected = selected ?? const [];

  final String id;
  final String text;
  final double? confidence;
  final String? ja;
  final List<Map<String, String>> suggestions; // [{en, desc}]
  final List<String> selected;
  final String? genre;
  final String? segment;

  factory Sentence.fromMap(Map<String, dynamic> map) {
    return Sentence(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble(),
      ja: map['ja'] as String?,
      suggestions: (map['suggestions'] as List<dynamic>?)
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
          const [],
      selected: (map['selected'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
      if (suggestions.isNotEmpty) 'suggestions': suggestions,
      if (selected.isNotEmpty) 'selected': selected,
      if (genre != null) 'genre': genre,
      if (segment != null) 'segment': segment,
    };
  }

  Sentence copyWith({
    String? id,
    String? text,
    double? confidence,
    String? ja,
    List<Map<String, String>>? suggestions,
    List<String>? selected,
    String? genre,
    String? segment,
  }) {
    return Sentence(
      id: id ?? this.id,
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      ja: ja ?? this.ja,
      suggestions: suggestions ?? this.suggestions,
      selected: selected ?? this.selected,
      genre: genre ?? this.genre,
      segment: segment ?? this.segment,
    );
  }

  static Sentence withGeneratedId(
    String text, {
    double? confidence,
    String? ja,
    List<Map<String, String>>? suggestions,
    List<String>? selected,
    String? genre,
    String? segment,
  }) {
    return Sentence(
      id: const Uuid().v4(),
      text: text,
      confidence: confidence,
      ja: ja,
      suggestions: suggestions ?? const [],
      selected: selected ?? const [],
      genre: genre,
      segment: segment,
    );
  }
}
