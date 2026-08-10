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
  /// Ekranı tazeleyen sayaç.
  Timer? _ticker;

  /// Günlük istatistiklere kısmi yazma yapan sayaç. Kronometre saatlerce
  /// çalışıp uygulama öldürülse bile liderlik tablosu güncel kalsın diye.
  Timer? _flusher;

  static const _flushEvery = Duration(seconds: 60);

  @override
  StopwatchState build() {
    ref.onDispose(_stopTimers);

    // Kaydedilmiş oturumu senkron geri yükle: uygulama kapanıp açılsa da
    // kronometre kaldığı yerden devam eder, sıfırlanmaz.
    final active = _storage.getActive();
    if (active != null && active.isRunning) _startTimers();
    return StopwatchState(session: active);
  }

  StudySessionStorage get _storage => ref.read(studySessionStorageProvider);
  DailyStudyStatsStorage get _dailyStats => ref.read(dailyStatsStorageProvider);
  StudyPresence? get _presence => ref.read(studyPresenceProvider);

  /// Sayaç sadece ekranı tazeler; süre her zaman [StudySession.elapsedSeconds]
  /// üzerinden duvar saatinden hesaplanır. Tick kaçırmak süreyi bozmaz.
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

  /// Son yazmadan bu yana geçen süreyi günlük istatistiklere ekler.
  ///
  /// Yalnızca **fark** yazılıyor ve yazılan miktar oturumun `flushedSeconds`
  /// alanına işleniyor. `stop()` de aynı alana bakıp yalnızca kalanı ekliyor —
  /// yoksa dakikada bir yazılan süre kapanışta ikinci kez sayılırdı.
  Future<void> _flush() async {
    final current = state.session;
    if (current == null || !current.isRunning) return;

    final delta = current.elapsedSeconds - current.flushedSeconds;
    if (delta <= 0) return;

    final marked = _copy(current, flushedSeconds: current.flushedSeconds + delta);
    _storage.save(marked); // Hive yazması senkron motorunda kirli işaretlenir
    state = StopwatchState(session: marked);

    await _dailyStats.addSeconds(
      date: DateTime.now(),
      seconds: delta,
      fromStopwatch: true,
    );
    // Yazma sırasında oturum kapanmış olabilir (çıkış yapmak provider'ı
    // dispose ediyor); dispose edilmiş ref'te invalidate hata fırlatır.
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
    await _flush(); // duraklamadan önce biriken farkı yaz

    final latest = state.session ?? current;

    // Geçen süreyi birikime yaz, resumedAt'i düşür: duraklama süresi sayılmaz.
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
    final current = state.session;
    if (current == null) return;

    _stopTimers();
    final total = current.elapsedSeconds;

    _storage.save(_copy(
      current,
      endTime: DateTime.now(),
      durationSeconds: total,
      clearResumedAt: true,
      flushedSeconds: total,
    ));

    // Kısmi yazmalarla zaten eklenen kısmı düş; kalanı ekle.
    final remaining = total - current.flushedSeconds;
    if (remaining > 0) {
      await _dailyStats.addSeconds(
        date: DateTime.now(),
        seconds: remaining,
        fromStopwatch: true,
      );
    }
    if (!ref.mounted) return;
    ref.invalidate(todayStatsProvider);

    state = const StopwatchState();
    await _presence?.setStudying(false);
  }

  /// Kaydetmeden at.
  void reset() {
    _ticker?.cancel();
    final current = state.session;
    if (current != null) _storage.delete(current.id);
    state = const StopwatchState();
  }
}
