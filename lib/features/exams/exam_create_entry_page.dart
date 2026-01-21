import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class ExamCreateEntryPage extends StatelessWidget {
  const ExamCreateEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deneme Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Deneme türü seç:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),

            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.black12,
              title: const Text('Genel Deneme'),
              subtitle: const Text('TYT / AYT denemeleri'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/exams/general/type');
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.black12,
              title: const Text('Branş Denemesi'),
              subtitle: const Text('Tek ders + konu seçimi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/exams/branch/lesson');
              },
            ),
          ],
        ),
      ),
    );
  }
}
