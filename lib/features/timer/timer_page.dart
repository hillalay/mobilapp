import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'stopwatch_controller.dart';
import '../topics/topic_providers.dart';

class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stopwatchProvider);
    final notifier = ref.read(stopwatchProvider.notifier);
    final topicsAsync = ref.watch(filteredTopicsProvider);

    return Scaffold(
      backgroundColor: state.isRunning ? Colors.green.shade50 : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Kronometre'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // ✅ AppBar'dan actions kaldırıldı
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
                lesson: state.lesson,
                topic: state.topic,
              ),

              const SizedBox(height: 40),

              // ✅ KONTROL BUTONLARI - 3 DURUMA GÖRE DEĞİŞİR
              _buildControlButtons(context, state, notifier),

              const SizedBox(height: 32),

              // Ders/Konu Seçimi
              if (!state.isRunning) ...[
                topicsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Hata: $e'),
                  data: (map) {
                    final lessons = map.keys.toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Ders ve Konu Seç',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: state.lesson,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.school_rounded),
                              hintText: 'Ders seç (opsiyonel)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Seçim yok')),
                              ...lessons.map((l) => DropdownMenuItem(value: l, child: Text(l))),
                            ],
                            onChanged: (value) {
                              notifier.setLesson(value);
                              notifier.setTopic(null);
                            },
                          ),
                        ),

                        if (state.lesson != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: state.topic,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.topic_rounded),
                                hintText: 'Konu seç (opsiyonel)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Seçim yok')),
                                ...(map[state.lesson] ?? [])
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t))),
                              ],
                              onChanged: notifier.setTopic,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ✅ BUTON DÜZENİNİ BELİRLEYEN FONKSİYON
  // Bu fonksiyon 3 farklı duruma göre buton düzeni oluşturur:
  // 1. Başlangıç: Sadece "Başlat" butonu
  // 2. Çalışıyor: "Duraklat" + "Kaydet" butonları
  // 3. Duraklatıldı: "Başlat" + "Sıfırla" + "Kaydet" butonları
  Widget _buildControlButtons(
    BuildContext context,
    StopwatchState state,
    StopwatchNotifier notifier,
  ) {
    // DURUM 1: Hiç başlatılmamış (seconds = 0 ve çalışmıyor)
    if (state.seconds == 0 && !state.isRunning) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CircularButton(
            onPressed: notifier.start,
            icon: Icons.play_arrow_rounded,
            color: Colors.green,
            size: 80,
            label: 'Başlat',
          ),
        ],
      );
    }

    // DURUM 2: Çalışıyor (isRunning = true)
    if (state.isRunning) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Duraklat butonu
          _CircularButton(
            onPressed: notifier.pause,
            icon: Icons.pause_rounded,
            color: Colors.orange,
            size: 80,
            label: 'Duraklat',
          ),
          
          const SizedBox(width: 20),
          
          // Kaydet butonu
          _CircularButton(
            onPressed: () async {
              await notifier.stop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('✓ Çalışma kaydedildi!'),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            icon: Icons.save_rounded,
            color: Colors.blue,
            size: 64,
            label: 'Kaydet',
          ),
        ],
      );
    }

    // DURUM 3: Duraklatılmış (seconds > 0 ama çalışmıyor)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Devam et butonu
        _CircularButton(
          onPressed: notifier.start,
          icon: Icons.play_arrow_rounded,
          color: Colors.green,
          size: 80,
          label: 'Devam',
        ),
        
        const SizedBox(width: 16),
        
        // Sıfırla butonu
        _CircularButton(
          onPressed: notifier.reset,
          icon: Icons.refresh_rounded,
          color: Colors.grey,
          size: 64,
          label: 'Sıfırla',
        ),
        
        const SizedBox(width: 16),
        
        // Kaydet butonu
        _CircularButton(
          onPressed: () async {
            await notifier.stop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✓ Çalışma kaydedildi!'),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
          icon: Icons.save_rounded,
          color: Colors.blue,
          size: 64,
          label: 'Kaydet',
        ),
      ],
    );
  }
}

// CircularTimer aynı kalıyor...
class CircularTimer extends StatelessWidget {
  const CircularTimer({
    super.key,
    required this.seconds,
    required this.isRunning,
    this.lesson,
    this.topic,
  });

  final int seconds;
  final bool isRunning;
  final String? lesson;
  final String? topic;

  String get formattedTime {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
                  color: isRunning ? Colors.green.shade700 : Colors.grey.shade700,
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
                      color: isRunning ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isRunning ? 'Çalışıyor' : 'Duraklatıldı',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (lesson != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isRunning ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.book,
                        size: 16,
                        color: isRunning ? Colors.green.shade700 : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$lesson${topic != null ? ' • $topic' : ''}',
                        style: TextStyle(
                          color: isRunning ? Colors.green.shade700 : Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  _CircularTimerPainter({required this.progress, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 6, bgPaint);

    final progressPaint = Paint()
      ..color = isRunning ? Colors.green : Colors.grey.shade400
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
    return oldDelegate.progress != progress || oldDelegate.isRunning != isRunning;
  }
}

// ✅ GÜNCELLENMIŞ YUVARLAK BUTON - LABEL EKLENDİ
class _CircularButton extends StatelessWidget {
  const _CircularButton({
    required this.onPressed,
    required this.icon,
    required this.color,
    this.size = 72,
    this.label, // ✅ Yeni parametre
  });

  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final double size;
  final String? label; // ✅ Opsiyonel yazı

  @override
  Widget build(BuildContext context) {
    // ✅ Column kullanarak buton + yazıyı dikey olarak yerleştiriyoruz
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Yuvarlak buton
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
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
        
        // ✅ Label (yazı) - varsa göster
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }
}