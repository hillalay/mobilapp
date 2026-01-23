import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'study_session.dart';
import 'study_session_storage.dart';

final studySessionStorageProvider = Provider((ref) => StudySessionStorage());

final studySessionsProvider = FutureProvider<List<StudySession>>((ref) async {
  return ref.read(studySessionStorageProvider).getAll();
});

final activeSessionProvider = FutureProvider<StudySession?>((ref) async {
  return ref.read(studySessionStorageProvider).getActive();
});