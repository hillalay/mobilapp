import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'study_session.dart';
import 'study_session_storage.dart';
import 'study_session_providers.dart';
import 'daily_study_stats_storage.dart';
import 'daily_study_stats_providers.dart';

class StopwatchState {
  final StudySession? session;

  const StopwatchState({this.session});

  int get seconds => session?.elapsedSeconds ?? 0;
  bool get isRunning => session?.isRunning ?? false;

  String get formattedTime {
    final s = seconds;
    final hours = s ~/ 3600;
    final minutes = (s % 3600) ~/ 60;
    final secs = s % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

final stopwatchProvider = NotifierProvider<StopwatchNotifier, StopwatchState>(
  StopwatchNotifier.new,
);

class StopwatchNotifier extends Notifier<StopwatchState> {
  Timer? _ticker;

  @override
  StopwatchState build() {
    ref.onDispose(() => _ticker?.cancel());

    // Kaydedilmiş oturumu senkron geri yükle: uygulama kapanıp açılsa da
    // kronometre kaldığı yerden devam eder, sıfırlanmaz.
    final active = _storage.getActive();
    if (active != null && active.isRunning) _startTicker();
    return StopwatchState(session: active);
  }

  StudySessionStorage get _storage => ref.read(studySessionStorageProvider);
  DailyStudyStatsStorage get _dailyStats => ref.read(dailyStatsStorageProvider);

  /// Sayaç sadece ekranı tazeler; süre her zaman [StudySession.elapsedSeconds]
  /// üzerinden duvar saatinden hesaplanır. Tick kaçırmak süreyi bozmaz.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = StopwatchState(session: state.session);
    });
  }

  void start() {
    final current = state.session;
    if (current != null && current.isRunning) return;

    final now = DateTime.now();
    final session = current == null
        ? StudySession(
            id: now.millisecondsSinceEpoch.toString(),
            startTime: now,
            durationSeconds: 0,
            resumedAt: now,
          )
        : StudySession(
            id: current.id,
            startTime: current.startTime,
            durationSeconds: current.durationSeconds,
            resumedAt: now,
          );

    _storage.save(session);
    state = StopwatchState(session: session);
    _startTicker();
  }

  void pause() {
    final current = state.session;
    if (current == null || !current.isRunning) return;

    _ticker?.cancel();

    // Geçen süreyi birikime yaz, resumedAt'i düşür: duraklama süresi sayılmaz.
    final paused = StudySession(
      id: current.id,
      startTime: current.startTime,
      durationSeconds: current.elapsedSeconds,
      resumedAt: null,
    );

    _storage.save(paused);
    state = StopwatchState(session: paused);
  }

  Future<void> stop() async {
    final current = state.session;
    if (current == null) return;

    _ticker?.cancel();
    final total = current.elapsedSeconds;

    _storage.save(StudySession(
      id: current.id,
      startTime: current.startTime,
      endTime: DateTime.now(),
      durationSeconds: total,
      resumedAt: null,
    ));

    await _dailyStats.addSeconds(date: DateTime.now(), seconds: total);
    ref.invalidate(todayStatsProvider);

    state = const StopwatchState();
  }

  /// Kaydetmeden at.
  void reset() {
    _ticker?.cancel();
    final current = state.session;
    if (current != null) _storage.delete(current.id);
    state = const StopwatchState();
  }
}
