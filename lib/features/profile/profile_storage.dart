import 'package:hive/hive.dart';
import 'profile_controller.dart';

class ProfileStorage {
  static const _boxName = 'profile_box';
  static const _key = 'profile';

  Future<Box> _open() async {
    return Hive.openBox(_boxName);
  }

  Future<void> save(UserProfile profile) async {
    final box = await _open();
    await box.put(_key, {
      'track': profile.track.name, // mf/tm/sozel/dil
    });
  }

  Future<UserProfile?> load() async {
    final box = await _open();
    final data = box.get(_key);
    if (data == null) return null;

    final map = Map<String, dynamic>.from(data);

    final trackStr = map['track'] as String?;
    if (trackStr == null) return null;

    // String -> enum
    final track = Track.values.byName(trackStr);

    return UserProfile(track: track);
  }

  Future<void> clear() async {
    final box = await _open();
    await box.delete(_key);
  }
}
