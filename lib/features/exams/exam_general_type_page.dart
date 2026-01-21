import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'exam_models.dart';


class ExamGeneralTypePage extends StatelessWidget {
  const ExamGeneralTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Genel Deneme')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Hangi sınav?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.black12,
              title: const Text('TYT'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/exams/general/form', extra: ExamType.tyt),

            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.black12,
              title: const Text('AYT'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/exams/general/form', extra: ExamType.ayt),

            ),
          ],
        ),
      ),
    );
  }
}
