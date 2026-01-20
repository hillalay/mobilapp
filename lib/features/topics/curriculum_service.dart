import 'dart:convert';
import 'package:flutter/services.dart';

class CurriculumService {
  Future<Map<String, dynamic>> load() async {
    final jsonStr = await rootBundle.loadString(
      'assets/data/curriculum.json',
    );
    return json.decode(jsonStr) as Map<String, dynamic>;
  }
}
