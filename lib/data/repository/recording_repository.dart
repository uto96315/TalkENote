import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../constants/recording_fields.dart';
import '../../constants/upload_status.dart';
import '../model/recording.dart';

class RecordingRepository {
  RecordingRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(RecordingFields.collection);

  String newRecordingId() => _collection.doc().id;

  Future<String> uploadRecording({
    required String userId,
    required String recordingId,
    required File file,
  }) async {
    final ref = _storage.ref('recordings/$userId/$recordingId.m4a');
    await ref.putFile(file);
    return ref.fullPath;
  }

  Future<void> saveMetadata({
    required String recordingId,
    required String userId,
    required String storagePath,
    required double durationSec,
    String? memo,
    String? title,
    List<String> newWords = const [],
    UploadStatus status = UploadStatus.uploaded,
  }) async {
    final recording = Recording(
      id: recordingId,
      userId: userId,
      storagePath: storagePath,
      durationSec: durationSec,
      uploadStatus: status,
      memo: memo,
      title: title,
      newWords: newWords,
    );
    await _collection.doc(recordingId).set(
          recording.toCreatePayload(),
          SetOptions(merge: true),
        );
  }

  Future<void> updateStatus({
    required String recordingId,
    required UploadStatus status,
    String? storagePath,
  }) async {
    await _collection.doc(recordingId).set(
          Recording.statusUpdate(
            status: status,
            newStoragePath: storagePath,
          ),
          SetOptions(merge: true),
        );
  }
}
