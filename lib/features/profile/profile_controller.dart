import 'package:flutter/material.dart';
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

  /// Hatırlatma saatinin dakikası (0-59). Onboarding sabit saatler sunduğu
  /// için oradan hep 0 gelir; profil ayarlarındaki saat seçici dakika da
  /// veriyor. Alan eklenmeden önce yazılmış kayıtlarda yok, 0 varsayılır.
  final int reminderMinute;

  /// Profil ayarlarındaki hatırlatıcı anahtarı. Varsayılan açık.
  ///
  /// [reminderHour] "saat seçilmedi / istemiyorum", bu alan ise "anahtarla
  /// kapattım" demek. İkisi [reminderTime] içinde VE'lendiği için çelişebilen
  /// iki ayrı "kapalı" durumu yok. Anahtar kapatılıp açıldığında saat
  /// korunduğundan hatırlatma kaldığı saatten devam eder.
  final bool reminderEnabled;

  const UserProfile({
    required this.track,
    this.dailyGoalHours,
    this.reminderHour,
    this.reminderMinute = 0,
    this.reminderEnabled = true,
  });

  /// Zamanlanacak saat; anahtar kapalıysa ya da saat seçilmemişse null.
  TimeOfDay? get reminderTime {
    final hour = reminderHour;
    if (!reminderEnabled || hour == null) return null;
    return TimeOfDay(hour: hour, minute: reminderMinute);
  }

  UserProfile copyWith({
    Track? track,
    int? dailyGoalHours,
    int? reminderHour,
    int? reminderMinute,
    bool? reminderEnabled,
  }) {
    return UserProfile(
      track: track ?? this.track,
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
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
