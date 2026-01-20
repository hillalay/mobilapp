import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_storage.dart';

enum UserRole { highSchool, university }
enum GradeGroup { g9_10, g11_12 }
enum Track { tm, mf, dil, sozel }

class UserProfile {
  final UserRole role;
  final GradeGroup? gradeGroup;
  final Track? track;

  const UserProfile({
    required this.role,
    this.gradeGroup,
    this.track,
  });
}

final profileStorageProvider = Provider<ProfileStorage>((ref) {
  return ProfileStorage();
});

class ProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final storage = ref.read(profileStorageProvider);
    return storage.load();
  }

  Future<void> setProfile(UserProfile profile) async {
    state = const AsyncLoading();
    final storage = ref.read(profileStorageProvider);
    await storage.save(profile);
    state = AsyncData(profile);
  }

  Future<void> clear() async {
    state = const AsyncLoading();
    final storage = ref.read(profileStorageProvider);
    await storage.clear();
    state = const AsyncData(null);
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(ProfileController.new);
