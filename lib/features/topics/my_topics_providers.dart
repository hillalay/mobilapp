import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'my_topic.dart';
import 'my_topics_storage.dart';

final myTopicsStorageProvider = Provider((ref) => MyTopicsStorage());

final myTopicsProvider = FutureProvider<List<MyTopic>>((ref) async {
  return ref.read(myTopicsStorageProvider).getAll();
});