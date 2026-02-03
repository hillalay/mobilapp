import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile/profile_controller.dart';
import 'curriculum_service.dart';
import 'topic_repository.dart';

final curriculumServiceProvider = Provider((ref) => CurriculumService());

final topicRepositoryProvider = Provider(
  (ref) => TopicRepository(ref.read(curriculumServiceProvider)),
);

//  TYT: profil bağımsız
final tytTopicsProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  return ref.read(topicRepositoryProvider).getTytTopics();
});

//  AYT: profile.track'a bağlı
final aytTopicsProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return <String, List<String>>{};
  return ref.read(topicRepositoryProvider).getAytTopics(profile);
});
final mergedTopicsProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return <String, List<String>>{};
  return ref.read(topicRepositoryProvider).getMergedTopics(profile);
});

