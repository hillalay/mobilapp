import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stopwatch_controller.dart';

class StopwatchPage extends ConsumerWidget {
  const StopwatchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stopwatchProvider);
    final controller = ref.read(stopwatchProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kronometre'),
        actions: [
          if (state.isRunning || state.seconds > 0)
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Durdur ve Kaydet',
              onPressed: () async {
                await controller.stop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Çalışma kaydedildi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: state.isRunning ? Colors.green.shade50 : null,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      state.formattedTime,
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: state.isRunning ? Colors.green.shade700 : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.isRunning ? 'Çalışıyor' : 'Duraklatıldı',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!state.isRunning)
                  FilledButton.icon(
                    onPressed: controller.start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Başlat'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                  ),
                if (state.isRunning)
                  FilledButton.icon(
                    onPressed: controller.pause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Duraklat'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      backgroundColor: Colors.orange,
                    ),
                  ),
                if (state.seconds > 0 && !state.isRunning) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: controller.reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Sıfırla'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}