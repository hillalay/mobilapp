import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/study_presence.dart';
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
  Timer? _flusher;
  Future<void>? _inFlightFlush;
  bool _stopping = false;

  static const _flushEvery = Duration(seconds: 60);

  @override
  StopwatchState build() {
    ref.onDispose(_stopTimers);
    final active = _storage.getActive();
    if (active != null && active.isRunning) _startTimers();
    return StopwatchState(session: active);
  }

  StudySessionStorage get _storage => ref.read(studySessionStorageProvider);
  DailyStudyStatsStorage get _dailyStats => ref.read(dailyStatsStorageProvider);
  StudyPresence? get _presence => ref.read(studyPresenceProvider);

  void _startTimers() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = StopwatchState(session: state.session);
    });

    _flusher?.cancel();
    _flusher = Timer.periodic(_flushEvery, (_) => _flush());
  }

  void _stopTimers() {
    _ticker?.cancel();
    _flusher?.cancel();
  }

  /// Aynı anda yalnızca bir flush çalışsın diye (pause/stop/periyodik timer
  /// çakışabiliyordu — B1). `stop()` ve `pause()` bu future'ı awaitleyerek
  /// bekleyen bir yazmanın bitmesini garantiler.
  Future<void> _flush() {
    if (_inFlightFlush != null) return _inFlightFlush!;
    final future = _doFlush();
    _inFlightFlush = future;
    future.whenComplete(() => _inFlightFlush = null);
    return future;
  }

  Future<void> _doFlush() async {
    final current = state.session;
    if (current == null || !current.isRunning) return;

    final delta = current.elapsedSeconds - current.flushedSeconds;
    if (delta <= 0) return;

    final now = DateTime.now();

    // ÖNCE günlük istatistiklere yaz (B2). Bu await sırasında hata olursa
    // ya da uygulama ölürse, flushedSeconds hiç artmamış olur — bir
    // sonraki flush/stop aynı deltayı tekrar dener, veri kaybolmaz.
    await _dailyStats.addSecondsSpan(
      start: now.subtract(Duration(seconds: delta)),
      end: now,
      fromStopwatch: true,
    );

    // Yazma başarıyla bittikten SONRA flushedSeconds'ı işaretle.
    final marked = _copy(current, flushedSeconds: current.flushedSeconds + delta);
    _storage.save(marked);
    state = StopwatchState(session: marked);

    if (ref.mounted) ref.invalidate(todayStatsProvider);
  }

  StudySession _copy(
    StudySession s, {
    DateTime? endTime,
    int? durationSeconds,
    DateTime? resumedAt,
    int? flushedSeconds,
    bool clearResumedAt = false,
  }) {
    return StudySession(
      id: s.id,
      startTime: s.startTime,
      endTime: endTime ?? s.endTime,
      durationSeconds: durationSeconds ?? s.durationSeconds,
      resumedAt: clearResumedAt ? null : (resumedAt ?? s.resumedAt),
      flushedSeconds: flushedSeconds ?? s.flushedSeconds,
    );
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
        : _copy(current, resumedAt: now);

    _storage.save(session);
    state = StopwatchState(session: session);
    _startTimers();
    _presence?.setStudying(true);
  }

  Future<void> pause() async {
    final current = state.session;
    if (current == null || !current.isRunning) return;

    _stopTimers();
    await _flush();

    final latest = state.session ?? current;
    final paused = _copy(
      latest,
      durationSeconds: latest.elapsedSeconds,
      clearResumedAt: true,
    );

    _storage.save(paused);
    state = StopwatchState(session: paused);
    await _presence?.setStudying(false);
  }

  Future<void> stop() async {
    // B8: çift tıklama koruması — stop() zaten çalışırken ikinci çağrı no-op.
    if (_stopping) return;
    _stopping = true;
    try {
      final current = state.session;
      if (current == null) return;

      _stopTimers();

      // Bekleyen bir flush varsa bitmesini bekle, flushedSeconds güncel olsun.
      await _flush();

      final latest = state.session ?? current;
      final total = latest.elapsedSeconds;
      final remaining = total - latest.flushedSeconds;

      if (remaining > 0) {
        final now = DateTime.now();
        await _dailyStats.addSecondsSpan(
          start: now.subtract(Duration(seconds: remaining)),
          end: now,
          fromStopwatch: true,
        );
      }

      _storage.save(_copy(
        latest,
        endTime: DateTime.now(),
        durationSeconds: total,
        clearResumedAt: true,
        flushedSeconds: total,
      ));

      if (ref.mounted) ref.invalidate(todayStatsProvider);

      state = const StopwatchState();
      await _presence?.setStudying(false);
    } finally {
      _stopping = false;
    }
  }

  void reset() {
    _ticker?.cancel();
    _flusher?.cancel(); // A4: önceden unutulmuştu, yetim timer sızıntısı
    final current = state.session;
    if (current != null) _storage.delete(current.id);
    state = const StopwatchState();
    _presence?.setStudying(false); // A4: önceden hiç çağrılmıyordu
  }
}