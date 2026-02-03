import '../profile/profile_controller.dart';
import 'curriculum_service.dart';

class TopicRepository {
  final CurriculumService service;
  TopicRepository(this.service);

  Future<Map<String, List<String>>> getTytTopics() async {
    final data = await service.load();
    final tyt = data['tyt'];
    if (tyt is! Map<String, dynamic>) return {};
    return _mapToStringList(tyt);
  }

  Future<Map<String, List<String>>> getAytTopics(UserProfile profile) async {
    final data = await service.load();

    final aytRoot = data['ayt'];
    if (aytRoot is! Map<String, dynamic>) return {};

    final trackKey = profile.track.name; // mf/tm/sozel/dil
    final trackSection = aytRoot[trackKey];
    if (trackSection is! Map<String, dynamic>) return {};

    return _mapToStringList(trackSection);
  }
  Future<Map<String, List<String>>> getMergedTopics(UserProfile profile) async {
    final tyt = await getTytTopics();
    final ayt = await getAytTopics(profile);

    final merged = <String, List<String>>{};

    void addAll(Map<String, List<String>> src) {
      for (final e in src.entries) {
        merged.putIfAbsent(e.key, () => <String>[]);
        merged[e.key]!.addAll(e.value);
    }
  }
  
  addAll(tyt);
  addAll(ayt);

  // duplicate temizle + sırala
  for (final k in merged.keys) {
    merged[k] = merged[k]!.toSet().toList()..sort();
  }

  return merged;
}


  Map<String, List<String>> _mapToStringList(Map<String, dynamic> raw) {
    return raw.map(
      (key, value) => MapEntry(key, List<String>.from(value as List)),
    );
  }
}
