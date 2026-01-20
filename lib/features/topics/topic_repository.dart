import '../profile/profile_controller.dart';
import 'curriculum_service.dart';

class TopicRepository {
  final CurriculumService service;
  TopicRepository(this.service);

  Future<Map<String, List<String>>> getTopicsForProfile(
    UserProfile profile,
  ) async {
    final data = await service.load();

    // 9–10 Lise
    if (profile.role == UserRole.highSchool &&
        profile.gradeGroup == GradeGroup.g9_10) {
      return _mapToStringList(
        data['lise_9_10'] as Map<String, dynamic>,
      );
    }

    // 11–12 Lise (AYT alan)
    if (profile.role == UserRole.highSchool &&
        profile.gradeGroup == GradeGroup.g11_12 &&
        profile.track != null) {
      final ayt = data['ayt'][profile.track!.name] as Map<String, dynamic>;
      return _mapToStringList(ayt);
    }

    // Üniversite (şimdilik boş)
    return {};
  }

  Map<String, List<String>> _mapToStringList(
    Map<String, dynamic> raw,
  ) {
    return raw.map(
      (key, value) => MapEntry(
        key,
        List<String>.from(value as List),
      ),
    );
  }
}
