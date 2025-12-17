import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository/recording_repository.dart';
import 'user_provider.dart';

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final recordingRepositoryProvider = Provider<RecordingRepository>((ref) {
  return RecordingRepository(
    ref.read(firestoreProvider),
    ref.read(firebaseStorageProvider),
  );
});

