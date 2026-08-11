import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_storage.dart';

// Sadece alanlar: MF/TM/Sözel/Dil
enum Track { mf, tm, sozel, dil }

/// Onboarding ve profil ayarları aynı seçenekleri gösteriyor; tek kaynak.
/// `(code, label)` — kod onboarding'deki 34×34 kutuda, etiket satırda.
const trackChoices = <Track, (String, String)>{
  Track.mf: ('MF', 'MF · Sayısal'),
  Track.tm: ('TM', 'TM · Eşit ağırlık'),
  Track.sozel: ('SÖZ', 'Sözel'),
  Track.dil: ('DİL', 'Dil'),
};

const goalHourChoices = <int, (String, String)>{
  2: ('2', '2 saat'),
  4: ('4', '4 saat'),
  6: ('6', '6 saat'),
  8: ('8+', '8 saat ve üzeri'),
};

const reminderChoices = <int?, (String, String)>{
  8: ('08', 'Sabah 08:00'),
  15: ('15', 'Öğleden sonra 15:00'),
  20: ('20', 'Akşam 20:00'),
  null: ('—', 'Hatırlatma istemiyorum'),
};

class UserProfile {
  final Track track;

  /// Onboarding 2. adım. null = seçilmedi (eski kayıtlar).
  final int? dailyGoalHours;

  /// Onboarding 3. adım: hatırlatma saati (0-23). null = hatırlatma istemiyor.
  final int? reminderHour;

  const UserProfile({
    required this.track,
    this.dailyGoalHours,
    this.reminderHour,
  });

  UserProfile copyWith({
    Track? track,
    int? dailyGoalHours,
    int? reminderHour,
  }) {
    return UserProfile(
      track: track ?? this.track,
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      reminderHour: reminderHour ?? this.reminderHour,
    );
  }
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
