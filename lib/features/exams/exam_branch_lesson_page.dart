import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExamBranchLessonPage extends StatelessWidget {
  const ExamBranchLessonPage({super.key});

  static const lessons = [
    'Türkçe',
    'Matematik',
    'Geometri',
    'Fizik',
    'Kimya',
    'Biyoloji',
    'Tarih',
    'Coğrafya',
    'Edebiyat',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Branş Denemesi')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: lessons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final lesson = lessons[i];
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.black12,
            title: Text(lesson),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
              context.push('/exams/branch/form', extra: lesson),
          );
        },
      ),
    );
  }
}
