import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<List<Recording>> fetchRecordingsByUser(String userId) async {
    final snap = await _collection
        .where(RecordingFields.userId, isEqualTo: userId)
        .orderBy(RecordingFields.createdAt, descending: true)
        .get();
    return snap.docs.map(Recording.fromDoc).toList();
  }

  Future<String> downloadUrl(String storagePath) async {
    return _storage.ref(storagePath).getDownloadURL();
  }

  Future<bool> existsInStorage(String storagePath) async {
    try {
      await _storage.ref(storagePath).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
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

  Future<void> reuploadFromStorage({
    required String recordingId,
    required String storagePath,
  }) async {
    final ref = _storage.ref(storagePath);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/reupload_$recordingId.m4a');

    await ref.writeToFile(tempFile); // throws if object not found
    await ref.putFile(tempFile);
    await updateStatus(
      recordingId: recordingId,
      status: UploadStatus.uploaded,
      storagePath: storagePath,
    );
    try {
      await tempFile.delete();
    } catch (_) {}
  }

  Future<void> updateInfo({
    required String recordingId,
    String? title,
    String? memo,
    List<String>? newWords,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload[RecordingFields.title] = title;
    if (memo != null) payload[RecordingFields.memo] = memo;
    if (newWords != null) payload[RecordingFields.newWords] = newWords;
    if (payload.isEmpty) return;

    await _collection.doc(recordingId).set(
          payload,
          SetOptions(merge: true),
        );
  }
}
