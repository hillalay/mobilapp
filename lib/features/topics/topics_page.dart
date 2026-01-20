import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'topic_providers.dart';

class TopicsPage extends ConsumerWidget {
  const TopicsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(filteredTopicsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Konu Takibi')),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (topics) => ListView(
          children: topics.entries.map((entry) {
            return ExpansionTile(
              title: Text(entry.key),
              children: entry.value
                  .map((t) => ListTile(title: Text(t)))
                  .toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
