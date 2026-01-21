import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exam_models.dart';
import 'exam_providers.dart';

/// Sadece general denemeler
final generalExamsProvider = Provider<List<ExamEntry>>((ref) {
  final async = ref.watch(examsProvider);
  return async.maybeWhen(
    data: (list) => list.where((e) => e.kind == ExamKind.general && e.general != null).toList(),
    orElse: () => const <ExamEntry>[],
  );
});

/// TYT genel denemeler
final tytGeneralExamsProvider = Provider<List<ExamEntry>>((ref) {
  final list = ref.watch(generalExamsProvider);
  return list.where((e) => e.general!.type == ExamType.tyt).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // tarih sırası
});

/// AYT genel denemeler
final aytGeneralExamsProvider = Provider<List<ExamEntry>>((ref) {
  final list = ref.watch(generalExamsProvider);
  return list.where((e) => e.general!.type == ExamType.ayt).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
});
