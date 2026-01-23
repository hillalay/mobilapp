import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'study_session.dart';
import 'study_session_storage.dart';
import 'study_session_providers.dart';

class StopwatchState {
  final int seconds;
  final bool isRunning;
  final String? lesson;
  final String? topic;
  final StudySession? activeSession;

  const StopwatchState({
    this.seconds = 0,
    this.isRunning = false,
    this.lesson,
    this.topic,
    this.activeSession,
  });

  StopwatchState copyWith({
    int? seconds,
    bool? isRunning,
    String? lesson,
    String? topic,
    StudySession? activeSession,
  }) {
    return StopwatchState(
      seconds: seconds ?? this.seconds,
      isRunning: isRunning ?? this.isRunning,
      lesson: lesson ?? this.lesson,
      topic: topic ?? this.topic,
      activeSession: activeSession ?? this.activeSession,
    );
  }

  String get formattedTime {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

final stopwatchProvider = NotifierProvider<StopwatchNotifier, StopwatchState>(
  StopwatchNotifier.new,
);

class StopwatchNotifier extends Notifier<StopwatchState> {
  Timer? _timer;

  @override
  StopwatchState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    _loadActiveSession();
    return const StopwatchState();
  }

  StudySessionStorage get _storage => ref.read(studySessionStorageProvider);

  Future<void> _loadActiveSession() async {
    final active = await _storage.getActive();
    if (active != null) {
      final elapsed = DateTime.now().difference(active.startTime).inSeconds;
      state = state.copyWith(
        seconds: elapsed,
        isRunning: true,
        lesson: active.lesson,
        topic: active.topic,
        activeSession: active,
      );
      _startTimer();
    }
  }

  void setLesson(String? lesson) {
    state = state.copyWith(lesson: lesson);
  }

  void setTopic(String? topic) {
    state = state.copyWith(topic: topic);
  }

  // ✅ DÜZELTME: start() fonksiyonu
  Future<void> start() async {
    if (state.isRunning) return;

    // ✅ Eğer activeSession varsa (durakladıktan sonra devam ediyoruz)
    if (state.activeSession != null) {
      // Sadece isRunning'i true yap, seconds'ı SIFIRLAMA!
      state = state.copyWith(isRunning: true);
      _startTimer();
      return;
    }

    // ✅ Yeni session başlatıyoruz (ilk kez başlatma)
    final session = StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      durationSeconds: 0,
      lesson: state.lesson,
      topic: state.topic,
    );

    await _storage.save(session);

    state = state.copyWith(
      isRunning: true,
      seconds: 0, // ✅ Sadece yeni başlatmada sıfırla
      activeSession: session,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(seconds: state.seconds + 1);
    });
  }

  Future<void> pause() async {
    if (!state.isRunning) return;

    _timer?.cancel();

    final session = state.activeSession;
    if (session != null) {
      final updated = StudySession(
        id: session.id,
        startTime: session.startTime,
        endTime: null,
        durationSeconds: state.seconds,
        lesson: session.lesson,
        topic: session.topic,
      );
      await _storage.save(updated);
    }

    state = state.copyWith(isRunning: false);
  }

  Future<void> stop() async {
    _timer?.cancel();

    final session = state.activeSession;
    if (session != null) {
      final completed = StudySession(
        id: session.id,
        startTime: session.startTime,
        endTime: DateTime.now(),
        durationSeconds: state.seconds,
        lesson: session.lesson,
        topic: session.topic,
      );
      await _storage.save(completed);
    }

    state = const StopwatchState();
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(seconds: 0, isRunning: false);
  }
}