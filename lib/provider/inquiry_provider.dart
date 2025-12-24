import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository/inquiry_repository.dart';
import 'user_provider.dart';

final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  return InquiryRepository(ref.read(firestoreProvider));
});

