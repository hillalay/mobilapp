import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_todo_section.dart';
import 'heatmap_section.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ NOTES + TODO
              ProfileTodoSection(),

              SizedBox(height: 24),

              // ✅ ISI HARİTASI 
              HeatmapSection(topTopicsPerLesson: 10),
            ],
          ),
        ),
      ),
    );
  }
}
