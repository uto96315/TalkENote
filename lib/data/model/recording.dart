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
