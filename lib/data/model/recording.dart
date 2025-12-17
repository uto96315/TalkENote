import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/recording_fields.dart';
import '../../constants/upload_status.dart';
import '../../constants/transcript_status.dart';
import 'sentence.dart';

class Recording {
  Recording({
    required this.id,
    required this.userId,
    required this.storagePath,
    required this.durationSec,
    required this.uploadStatus,
    this.createdAt,
    this.memo,
    this.title,
    List<String>? newWords,
    this.transcriptRaw,
    List<Sentence>? sentences,
    this.transcriptStatus = TranscriptStatus.idle,
  })  : newWords = newWords ?? const [],
        sentences = sentences ?? const [];

  final String id;
  final String userId;
  final String storagePath;
  final double durationSec;
  final UploadStatus uploadStatus;
  final Timestamp? createdAt;
  final String? memo;
  final String? title;
  final List<String> newWords;
  final String? transcriptRaw;
  final List<Sentence> sentences;
  final TranscriptStatus transcriptStatus;

  factory Recording.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Recording(
      id: doc.id,
      userId: data[RecordingFields.userId] as String? ?? '',
      storagePath: data[RecordingFields.storagePath] as String? ?? '',
      durationSec: (data[RecordingFields.durationSec] as num?)?.toDouble() ?? 0,
      uploadStatus: UploadStatusX.fromValue(
        data[RecordingFields.uploadStatus] as String? ?? '',
      ),
      createdAt: data[RecordingFields.createdAt] as Timestamp?,
      memo: data[RecordingFields.memo] as String? ?? '',
      title: data[RecordingFields.title] as String?,
      newWords: (data[RecordingFields.newWords] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      transcriptRaw: data[RecordingFields.transcriptRaw] as String?,
      sentences: (data[RecordingFields.sentences] as List<dynamic>?)
              ?.map((e) {
                if (e is Map<String, dynamic>) {
                  return Sentence.fromMap(e);
                }
                if (e is Map) {
                  return Sentence.fromMap(Map<String, dynamic>.from(e));
                }
                return null;
              })
              .whereType<Sentence>()
              .toList() ??
          const [],
      transcriptStatus: TranscriptStatusX.fromValue(
        data[RecordingFields.transcriptStatus] as String? ?? '',
      ),
    );
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      RecordingFields.userId: userId,
      // storagePath is no longer stored
      RecordingFields.durationSec: durationSec,
      RecordingFields.uploadStatus: uploadStatus.value,
      RecordingFields.createdAt: FieldValue.serverTimestamp(),
      RecordingFields.memo: memo ?? '',
      if (title != null && title!.isNotEmpty) RecordingFields.title: title,
      RecordingFields.newWords: newWords,
      if (transcriptRaw != null) RecordingFields.transcriptRaw: transcriptRaw,
      if (sentences.isNotEmpty)
        RecordingFields.sentences: sentences.map((s) => s.toMap()).toList(),
      RecordingFields.transcriptStatus: transcriptStatus.value,
    };
  }

  Map<String, dynamic> toStatusUpdate({
    required UploadStatus status,
    String? newStoragePath,
  }) {
    return {
      RecordingFields.uploadStatus: status.value,
      // storagePath is no longer stored
    };
  }

  static Map<String, dynamic> statusUpdate({
    required UploadStatus status,
    String? newStoragePath,
  }) {
    return {
      RecordingFields.uploadStatus: status.value,
      if (newStoragePath != null) RecordingFields.storagePath: newStoragePath,
    };
  }

  Recording copyWith({
    String? id,
    String? userId,
    String? storagePath,
    double? durationSec,
    UploadStatus? uploadStatus,
    Timestamp? createdAt,
    String? memo,
    String? title,
    List<String>? newWords,
    String? transcriptRaw,
    List<Sentence>? sentences,
    TranscriptStatus? transcriptStatus,
  }) {
    return Recording(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storagePath: storagePath ?? this.storagePath,
      durationSec: durationSec ?? this.durationSec,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      createdAt: createdAt ?? this.createdAt,
      memo: memo ?? this.memo,
      title: title ?? this.title,
      newWords: newWords ?? this.newWords,
      transcriptRaw: transcriptRaw ?? this.transcriptRaw,
      sentences: sentences ?? this.sentences,
      transcriptStatus: transcriptStatus ?? this.transcriptStatus,
    );
  }
}
