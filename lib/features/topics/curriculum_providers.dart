import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'curriculum_service.dart';

final curriculumServiceProvider = Provider<CurriculumService>((ref) {
  return CurriculumService();
});
