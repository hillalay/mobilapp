import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'profile_controller.dart';

/// Profilde seçilen saatte günlük tekrarlayan çalışma hatırlatması.
///
/// Yalnızca Android hedefleniyor: iOS/macOS init ayarları ve izin akışı
/// eklenmedi, o platformlarda eklenti çağrıları sessizce sonuçsuz kalır.
class StudyReminderNotifications {
  static const _channelId = 'study_reminder';
  static const _channelName = 'Çalışma hatırlatıcısı';
  static const _channelDescription =
      'Profilde seçtiğin saatte günlük çalışma hatırlatması.';

  /// Sabit id: her zamanlama eskisinin üzerine yazsın, bildirim birikmesin.
  /// Saat değiştiğinde ayrıca iptal etmek gerekmiyor.
  static const notificationId = 1001;

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  /// Tembel kurulum: ilk zamanlama/iptalde bir kez çalışır, sonraki çağrılar
  /// aynı future'ı bekler. main() içine ayrı bir açılış adımı gerekmiyor.
  Future<void> _init() => _ready ??= _doInit();

  Future<void> _doInit() async {
    tz_data.initializeTimeZones();

    // zonedSchedule saati yerel dilime göre hesaplıyor; cihazın dilimi
    // ayarlanmazsa UTC varsayılır ve bildirim yanlış saatte çalar.
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // Android 13+ çalışma zamanı izni. Reddedilirse zamanlama yine kurulur,
    // yalnızca gösterilmez; kullanıcı izni sonradan verirse çalışmaya başlar.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// [time] saatinde her gün tekrarlayan bildirimi kurar. Aynı id'ye
  /// yazdığı için önceki zamanlamayı üzerine alır.
  Future<void> scheduleDaily({required TimeOfDay time}) async {
    await _init();

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'Çalışma vakti',
      body: 'Bugün çalışmaya başlama saatin geldi',
      scheduledDate: _nextInstanceOf(time),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      // ponytail: inexact yeterli. USE_EXACT_ALARM Play incelemesinde alarm/
      // takvim uygulamalarına ayrılmış, SCHEDULE_EXACT_ALARM ise Android 13+'ta
      // kullanıcının ayarlardan elle vermesi gereken izin. Bildirim birkaç
      // dakika kayabilir; dakika hassasiyeti şart olursa exactAllowWhileIdle'a
      // geçilip manifest'e ilgili izin eklenir.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Günlük tekrarın standart yolu: yalnızca saat/dakika eşleşmesi aranır.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    await _init();
    await _plugin.cancel(id: notificationId);
  }

  /// Bugün o saat geçtiyse yarına kurulur; ilk tetiklenme hep ileride olur.
  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }
}

final studyReminderProvider = Provider<StudyReminderNotifications>((ref) {
  return StudyReminderNotifications();
});

/// Zamanlamayı profildeki saate eşitler.
///
/// Tek kanca: ayarlar ekranı, onboarding ve senkronla başka cihazdan gelen
/// profil değişikliği hepsi `profileProvider` üzerinden buraya düşüyor, o
/// yüzden `setProfile` içine ayrı bir çağrı konmadı. Açılışta profil ilk
/// yüklendiğinde de çalıştığı için, cihaz yeniden başladıktan sonra
/// zamanlama silinmiş olsa bile ilk açılışta yeniden kurulur.
final studyReminderBootstrapProvider = Provider<void>((ref) {
  final service = ref.watch(studyReminderProvider);
  final profileAsync = ref.watch(profileProvider);

  // Profil henüz yüklenmediyse dokunma: AsyncLoading anında cancel() çağırmak
  // her açılışta zamanlamayı boşuna silerdi.
  if (profileAsync.isLoading) return;

  final time = profileAsync.value?.reminderTime;
  final done = time == null ? service.cancel() : service.scheduleDaily(time: time);

  // İzin yok / eklenti hatası uygulamayı çökertmesin.
  done.catchError((Object e) {
    debugPrint('[reminder] zamanlama kurulamadı: $e');
  });
});
