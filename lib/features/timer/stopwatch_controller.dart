import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'study_session.dart';
import 'study_session_storage.dart';
import 'study_session_providers.dart';
import 'daily_study_stats_storage.dart';
import 'daily_study_stats_providers.dart';

class StopwatchState {
  final int seconds;
  final bool isRunning;
  final StudySession? activeSession;

  const StopwatchState({
    this.seconds = 0,
    this.isRunning = false,
    this.activeSession,
  });

  StopwatchState copyWith({
    int? seconds,
    bool? isRunning,
    StudySession? activeSession,
  }) {
    return StopwatchState(
      seconds: seconds ?? this.seconds,
      isRunning: isRunning ?? this.isRunning,
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
    
    // ✅ DÜZELTME: Aktif session'ı yükleme ama otomatik başlatma
    _loadActiveSessionWithoutAutoStart();
    
    return const StopwatchState();
  }

  StudySessionStorage get _storage => ref.read(studySessionStorageProvider);
  DailyStudyStatsStorage get _dailyStats => ref.read(dailyStatsStorageProvider);

  // ✅ YENİ FONKSİYON: Session'ı yükle ama timer'ı başlatma
  Future<void> _loadActiveSessionWithoutAutoStart() async {
    final active = await _storage.getActive();
    if (active != null) {
      final elapsed = DateTime.now().difference(active.startTime).inSeconds;
      state = state.copyWith(
        seconds: elapsed,
        isRunning: false, // ✅ ÖNEMLİ: Her zaman false olarak başlat
        activeSession: active,
      );
      // ✅ _startTimer() çağrısını KALDIRDIK - Artık otomatik başlamayacak
    }
  }

  // ❌ ESKİ FONKSİYON (artık kullanılmıyor, silebilirsiniz)
  // Future<void> _loadActiveSession() async {
  //   final active = await _storage.getActive();
  //   if (active != null) {
  //     final elapsed = DateTime.now().difference(active.startTime).inSeconds;
  //     state = state.copyWith(
  //       seconds: elapsed,
  //       isRunning: true,  // ← SORUN BURASI
  //       activeSession: active,
  //     );
  //     _startTimer();  // ← VE BURASI
  //   }
  // }

  Future<void> start() async {
    if (state.isRunning) return;

    // Durakladıktan sonra devam ediyoruz
    if (state.activeSession != null) {
      state = state.copyWith(isRunning: true);
      _startTimer();
      return;
    }

    // Yeni session başlat
    final session = StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      durationSeconds: 0,
    );

    await _storage.save(session);

    state = state.copyWith(
      isRunning: true,
      seconds: 0,
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
      );
      await _storage.save(updated);
    }

    state = state.copyWith(isRunning: false);
  }

  Future<void> stop() async {
    _timer?.cancel();

    final session = state.activeSession;
    final seconds = state.seconds;

    if (session != null) {
      final completed = StudySession(
        id: session.id,
        startTime: session.startTime,
        endTime: DateTime.now(),
        durationSeconds: state.seconds,
      );
      await _storage.save(completed);

      // Günlük istatistiklere ekle
      await _dailyStats.addSeconds(
        date: DateTime.now(),
        seconds: seconds,
      );
      
      // Provider'ı yenile
      ref.invalidate(todayStatsProvider);
    }

    state = const StopwatchState();
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(seconds: 0, isRunning: false);
  }
}