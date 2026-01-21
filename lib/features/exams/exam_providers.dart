import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exam_storage.dart';
import 'exam_models.dart';

final examStorageProvider = Provider((ref) => ExamStorage());

final examsProvider = FutureProvider<List<ExamEntry>>((ref) async {
  return ref.read(examStorageProvider).getAll();
});
