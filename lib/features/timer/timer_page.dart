import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_providers.dart';
import '../../app/theme.dart';
import 'stopwatch_controller.dart';

class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stopwatchProvider);
    final notifier = ref.read(stopwatchProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kronometre'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Supabase yapılandırılmamışsa liderlik tablosu da yok.
          if (ref.watch(supabaseClientProvider) != null)
            IconButton(
              icon: Icon(Icons.emoji_events_outlined, color: context.colors.brand),
              tooltip: 'Liderlik Tablosu',
              onPressed: () => context.push('/timer/leaderboard'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Yuvarlak Kronometre
              CircularTimer(
                seconds: state.seconds,
                isRunning: state.isRunning,
              ),

              const SizedBox(height: 40),

              // Kontrol butonları
              _buildControlButtons(context, state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    StopwatchState state,
    StopwatchNotifier notifier,
  ) {
    if (state.seconds == 0 && !state.isRunning) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CircularButton(
            onPressed: notifier.start,
            icon: Icons.play_arrow_rounded,
            color: context.colors.brand,
            size: 80,
            label: 'Başlat',
          ),
        ],
      );
    }

    if (state.isRunning) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CircularButton(
            onPressed: notifier.pause,
            icon: Icons.pause_rounded,
            color: context.colors.ink,
            size: 80,
            label: 'Duraklat',
          ),
          const SizedBox(width: 20),
          _CircularButton(
            onPressed: () async {
              await notifier.stop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('✓ Çalışma kaydedildi!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            icon: Icons.save_rounded,
            color: context.colors.brand,
            size: 64,
            label: 'Kaydet',
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircularButton(
          onPressed: notifier.start,
          icon: Icons.play_arrow_rounded,
          color: context.colors.brand,
          size: 80,
          label: 'Devam',
        ),
        const SizedBox(width: 16),
        _CircularButton(
          onPressed: notifier.reset,
          icon: Icons.refresh_rounded,
          color: context.colors.inkMuted,
          size: 64,
          label: 'Sıfırla',
        ),
        const SizedBox(width: 16),
        _CircularButton(
          onPressed: () async {
            await notifier.stop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✓ Çalışma kaydedildi!'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
          icon: Icons.save_rounded,
          color: context.colors.ink,
          size: 64,
          label: 'Kaydet',
        ),
      ],
    );
  }
}

class CircularTimer extends StatelessWidget {
  const CircularTimer({
    super.key,
    required this.seconds,
    required this.isRunning,
  });

  final int seconds;
  final bool isRunning;

  String get formattedTime {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(280, 280),
            painter: _CircularTimerPainter(
              progress: (seconds % 60) / 60.0,
              isRunning: isRunning,
              trackColor: c.barTrack,
              runningColor: c.success,
              pausedColor: c.brand,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: isRunning ? c.success : c.ink,
                  letterSpacing: 2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isRunning ? c.success : c.inkFaint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isRunning ? 'Çalışıyor' : 'Duraklatıldı',
                    style: TextStyle(
                      color: c.inkMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final bool isRunning;
  final Color trackColor;
  final Color runningColor;
  final Color pausedColor;

  _CircularTimerPainter({
    required this.progress,
    required this.isRunning,
    required this.trackColor,
    required this.runningColor,
    required this.pausedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 6, bgPaint);

    final progressPaint = Paint()
      ..color = isRunning ? runningColor : pausedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.pausedColor != pausedColor;
  }
}

class _CircularButton extends StatelessWidget {
  const _CircularButton({
    required this.onPressed,
    required this.icon,
    required this.color,
    this.size = 72,
    this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              elevation: 0,
            ),
            child: Icon(icon, size: size * 0.45),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.inkMuted,
            ),
          ),
        ],
      ],
    );
  }
}