import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'topic_progress_storage.dart';
import 'topic_progress.dart';

final topicProgressStorageProvider =
    Provider((ref) => TopicProgressStorage());

final topicProgressMapProvider =
    FutureProvider<Map<String, TopicProgress>>((ref) async {
  return ref.read(topicProgressStorageProvider).getAll();
});
