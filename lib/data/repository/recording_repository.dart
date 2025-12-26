import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../constants/recording_fields.dart';
import '../../constants/upload_status.dart';
import '../../constants/transcript_status.dart';
import '../../service/ai/translation_suggestion_service.dart';
import '../model/recording.dart';
import '../model/sentence.dart';

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

  Future<Recording?> fetchRecordingById(String recordingId) async {
    final doc = await _collection.doc(recordingId).get();
    if (!doc.exists) return null;
    // DocumentSnapshotをQueryDocumentSnapshotとして扱うために、データを再構築
    final data = doc.data();
    if (data == null) return null;
    // Recording.fromDocはQueryDocumentSnapshotを期待しているが、
    // 実際にはMap<String, dynamic>から構築できるようにする必要がある
    // 簡易的に、idとdataを組み合わせてRecordingを作成
    return Recording(
      id: doc.id,
      userId: data[RecordingFields.userId] as String? ?? '',
      storagePath: data[RecordingFields.storagePath] as String? ?? '',
      durationSec: (data[RecordingFields.durationSec] as num?)?.toDouble() ?? 0,
      uploadStatus: UploadStatusX.fromValue(
        data[RecordingFields.uploadStatus] as String? ?? '',
      ),
      createdAt: data[RecordingFields.createdAt] as Timestamp?,
      memo: data[RecordingFields.memo] as String?,
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
      words: (data[RecordingFields.words] as List<dynamic>?)
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
              .toList() ??
          const [],
      grammar: (data[RecordingFields.grammar] as List<dynamic>?)
              ?.map((e) {
                if (e is Map<String, dynamic>) {
                  return GrammarInfo.fromMap(e);
                }
                if (e is Map) {
                  return GrammarInfo.fromMap(Map<String, dynamic>.from(e));
                }
                return null;
              })
              .whereType<GrammarInfo>()
              .toList() ??
          const [],
    );
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
    required double durationSec,
    String? memo,
    String? title,
    List<String> newWords = const [],
    UploadStatus status = UploadStatus.uploaded,
  }) async {
    final recording = Recording(
      id: recordingId,
      userId: userId,
      storagePath: '',
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
            newStoragePath: null,
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

  Future<void> updateTranscriptRaw({
    required String recordingId,
    required String transcriptRaw,
  }) async {
    await _collection.doc(recordingId).set(
      {
        RecordingFields.transcriptRaw: transcriptRaw,
        RecordingFields.transcriptStatus: TranscriptStatus.done.value,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateTranscriptStatus({
    required String recordingId,
    required TranscriptStatus status,
  }) async {
    await _collection.doc(recordingId).set(
      {RecordingFields.transcriptStatus: status.value},
      SetOptions(merge: true),
    );
  }

  Future<void> updateSentences({
    required String recordingId,
    required List<Sentence> sentences,
  }) async {
    await _collection.doc(recordingId).set(
      {
        RecordingFields.sentences:
            sentences.map((s) => s.toMap()).toList(growable: false),
      },
      SetOptions(merge: true),
    );
  }

  /// 単語と文法情報を更新
  Future<void> updateWordsAndGrammar({
    required String recordingId,
    required List<WordInfo> words,
    required List<GrammarInfo> grammar,
  }) async {
    await _collection.doc(recordingId).set(
      {
        RecordingFields.words: words.map((w) => w.toMap()).toList(),
        RecordingFields.grammar: grammar.map((g) => g.toMap()).toList(),
      },
      SetOptions(merge: true),
    );
  }
}
