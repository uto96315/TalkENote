import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/recording_fields.dart';
import '../../constants/upload_status.dart';

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
  }) : newWords = newWords ?? const [];

  final String id;
  final String userId;
  final String storagePath;
  final double durationSec;
  final UploadStatus uploadStatus;
  final Timestamp? createdAt;
  final String? memo;
  final String? title;
  final List<String> newWords;

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
    );
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      RecordingFields.userId: userId,
      RecordingFields.storagePath: storagePath,
      RecordingFields.durationSec: durationSec,
      RecordingFields.uploadStatus: uploadStatus.value,
      RecordingFields.createdAt: FieldValue.serverTimestamp(),
      RecordingFields.memo: memo ?? '',
      if (title != null && title!.isNotEmpty) RecordingFields.title: title,
      RecordingFields.newWords: newWords,
    };
  }

  Map<String, dynamic> toStatusUpdate({
    required UploadStatus status,
    String? newStoragePath,
  }) {
    return {
      RecordingFields.uploadStatus: status.value,
      if (newStoragePath != null) RecordingFields.storagePath: newStoragePath,
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
}
