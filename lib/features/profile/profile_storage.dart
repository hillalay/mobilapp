import 'package:hive/hive.dart';
import 'profile_controller.dart';

class ProfileStorage {
  static const _boxName = 'profile_box';
  static const _key = 'user_profile';

  Future<Box> _open() async => Hive.openBox(_boxName);

  Future<void> save(UserProfile profile) async {
    final box = await _open();
    await box.put(_key, {
      'role': profile.role.name,
      'gradeGroup': profile.gradeGroup?.name,
      'track': profile.track?.name,
    });
  }

  Future<UserProfile?> load() async {
    final box = await _open();
    final data = box.get(_key);
    if (data == null) return null;

    final map = Map<String, dynamic>.from(data);

    final role = UserRole.values.byName(map['role'] as String);

    final ggName = map['gradeGroup'] as String?;
    final trName = map['track'] as String?;

    final gradeGroup = ggName == null ? null : GradeGroup.values.byName(ggName);
    final track = trName == null ? null : Track.values.byName(trName);

    return UserProfile(role: role, gradeGroup: gradeGroup, track: track);
  }

  Future<void> clear() async {
    final box = await _open();
    await box.delete(_key);
  }
}
