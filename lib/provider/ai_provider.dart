import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../service/ai/sentence_splitter_service.dart';
import '../service/ai/transcription_service.dart';
import '../service/ai/translation_suggestion_service.dart';

final openAiApiKeyProvider = Provider<String?>(
  (_) => dotenv.env['OPENAI_API_KEY'],
);

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  return TranscriptionService(
    apiKey: ref.watch(openAiApiKeyProvider),
  );
});

final sentenceSplitterServiceProvider =
    Provider<SentenceSplitterService>((ref) {
  return SentenceSplitterService(
    apiKey: ref.watch(openAiApiKeyProvider),
  );
});

final translationSuggestionServiceProvider =
    Provider<TranslationSuggestionService>((ref) {
  return TranslationSuggestionService(
    apiKey: ref.watch(openAiApiKeyProvider),
  );
});

