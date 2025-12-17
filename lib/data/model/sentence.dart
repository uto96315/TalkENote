import 'package:uuid/uuid.dart';

class Sentence {
  Sentence({
    required this.id,
    required this.text,
    this.confidence,
  });

  final String id;
  final String text;
  final double? confidence;

  factory Sentence.fromMap(Map<String, dynamic> map) {
    return Sentence(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      if (confidence != null) 'confidence': confidence,
    };
  }

  Sentence copyWith({
    String? id,
    String? text,
    double? confidence,
  }) {
    return Sentence(
      id: id ?? this.id,
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
    );
  }

  static Sentence withGeneratedId(String text, {double? confidence}) {
    return Sentence(
      id: const Uuid().v4(),
      text: text,
      confidence: confidence,
    );
  }
}
