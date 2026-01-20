import 'package:flutter/material.dart';

class ExamsPage extends StatelessWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Denemeler')),
      body: const Center(child: Text('Exams Page')),
    );
  }
}
