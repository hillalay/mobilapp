import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/exams/exam_storage.dart';
import '../features/profile/profile_storage.dart';
import '../features/timer/daily_study_stats_storage.dart';
import '../features/timer/study_session_storage.dart';
import '../features/topics/topic_progress_storage.dart';
import '../features/topics/my_topics_storage.dart';

/// Offline-first senkron: Hive ana kaynak, Supabase yedek/ortak kaynak.
///
/// Yerel yazmalar `box.watch()` ile yakalanıp "kirli" işaretlenir, tek bir
/// `records` tablosuna push edilir. Çekmede sunucunun `updated_at` imleci
/// kullanılır. Çakışmada son yazan kazanır (last-write-wins).
///
/// ponytail: LWW yeterli çünkü satırlar tek kullanıcıya ait, çakışma ancak
/// aynı kaydı iki cihazda aynı anda düzenleyince olur. Alan bazlı birleştirme
/// gerekirse `records`'a sürüm kolonu eklenip burada çözülür.
class SyncEngine {
  SyncEngine(this._client);

  final SupabaseClient _client;

  /// Supabase `collection` değeri -> yerel Hive kutusu.
  /// Kutu adları depolama sınıflarından geliyor: kopya string = sessizce
  /// senkron dışı kalan kutu.
  static const collections = <String, String>{
    'study_sessions': StudySessionStorage.boxName,
    'daily_study_stats': DailyStudyStatsStorage.boxName,
    'topic_progress': TopicProgressStorage.boxName,
    'exams': ExamStorage.boxName,
    'profile': ProfileStorage.boxName,
    'my_topics': MyTopicsStorage.boxName,
  };

  static const _dirtyBoxName = 'sync_dirty_box';
  static const _metaBoxName = 'sync_meta_box';
  static const _cursorKey = 'lastPulledAt';

  static const _debounce = Duration(seconds: 2);

  /// Kirli kayıt varken bu aralıkla gönderiliyor. Kronometre çalışırken
  /// dakikada bir kısmi yazma geldiği için liderlik tablosu yarım dakikadan
  /// fazla geride kalmıyor.
  static const _tickEvery = Duration(seconds: 30);

  /// Çekme daha seyrek: kirli kayıt yoksa ağ trafiği boşuna harcanmasın.
  static const _pullEveryTicks = 4; // 4 x 30 sn = 2 dk

  /// Senkronlanan tüm kutular main() içinde açılır: hem `watch()` dinleyebilmek
  /// hem de kronometrenin ilk karede senkron okuyabilmesi için.
  static Future<void> openBoxes() async {
    for (final name in collections.values) {
      await Hive.openBox(name);
    }
    await Hive.openBox(_dirtyBoxName);
    await Hive.openBox(_metaBoxName);
  }

  Box get _dirty => Hive.box(_dirtyBoxName);
  Box get _meta => Hive.box(_metaBoxName);

  final _subs = <StreamSubscription<BoxEvent>>[];
  final _suppressed = <String>{};
  Timer? _debounceTimer;
  Timer? _retryTimer;
  Future<void>? _startFuture;

  /// Giriş yapıldığında çağrılır. İlk çekmeyi bekler ki uygulama doğru veriyle
  /// açılsın. Aynı anda birden çok çağrı gelirse hepsi aynı ilk çekmeyi bekler.
  Future<void> start() => _startFuture ??= _start();

  Future<void> _start() async {
    for (final entry in collections.entries) {
      final collection = entry.key;
      final box = Hive.box(entry.value);
      _subs.add(box.watch().listen((event) {
        final id = '$collection|${event.key}';
        if (_suppressed.remove(id)) return; // sunucudan gelen değişiklik
        _dirty.put(id, true);
        _scheduleFlush();
      }));
    }

    _retryTimer = Timer.periodic(_tickEvery, (_) => _tick());

    await pull();
    await push();
  }

  Future<void> stop() async {
    _startFuture = null;
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _suppressed.clear();
  }

  void _scheduleFlush() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, push);
  }

  /// Çıkışta yerel veriyi siler: bir sonraki hesap öncekinin verisini görmesin.
  Future<void> clearLocal() async {
    for (final name in collections.values) {
      await Hive.box(name).clear();
    }
    await _dirty.clear();
    await _meta.clear();
  }

  int _ticks = 0;

  /// 30 sn'de bir: kirli kayıt varsa hemen gönder, çekmeyi 2 dakikada bir yap.
  Future<void> _tick() async {
    _ticks++;
    if (_dirty.isNotEmpty) await push();
    if (_ticks % _pullEveryTicks == 0) await pull();
  }

  // ---------------------------------------------------------------------------

  /// Konsolda izlenebilsin diye tek noktadan log. `flutter run` çıktısında
  /// `[sync]` ile aratabilirsin.
  static void _log(String message) => debugPrint('[sync] $message');

  Future<void> push() async {
    final userId = _client.auth.currentUser?.id;

    // Sessiz çıkışları görünür yap: "hiç denemedi" ile "denedi ve başardı"
    // konsolda ayırt edilebilsin.
    if (userId == null) {
      _log('push atlandı: oturum yok (${_dirty.length} kirli kayıt bekliyor)');
      return;
    }
    if (_dirty.isEmpty) {
      _log('push atlandı: kirli kayıt yok');
      return;
    }

    // Anahtarları önce sabitle: push sürerken gelen yeni yazmalar kirli kalsın.
    final ids = _dirty.keys.map((k) => k.toString()).toList();
    final rows = <Map<String, dynamic>>[];

    // Gönderilen değerin parmak izi. Upsert bittiğinde kutudaki değer hâlâ
    // aynıysa kirli işaret silinir; push sürerken üzerine yazılmışsa korunur.
    final sent = <String, String>{};

    for (final id in ids) {
      final sep = id.indexOf('|');
      if (sep < 0) continue;
      final collection = id.substring(0, sep);
      final key = id.substring(sep + 1);

      final boxName = collections[collection];
      if (boxName == null) continue;

      final raw = Hive.box(boxName).get(key);
      sent[id] = _fingerprint(raw);
      rows.add({
        'user_id': userId,
        'collection': collection,
        'key': key,
        'data': raw == null ? null : _jsonSafe(raw),
        'deleted': raw == null,
      });
    }

    if (rows.isEmpty) {
      _log('push atlandı: gönderilecek satır çıkmadı');
      return;
    }

    _log('push deneniyor: ${rows.length} satır '
        '(${rows.map((r) => '${r['collection']}/${r['key']}').join(', ')})');

    try {
      await _client.from('records').upsert(rows, onConflict: 'user_id,collection,key');

      // `deleteAll(ids)`, upsert sürerken aynı anahtara gelen yeni yerel
      // yazmanın kirli işaretini de siliyordu: o veri bir daha hiç
      // gönderilmiyordu. Artık yalnızca gönderdiğimiz değer hâlâ kutudaysa
      // işaret siliniyor, değiştiyse korunuyor ve sonraki push'a kalıyor.
      final kept = <String>[];
      for (final entry in sent.entries) {
        if (_fingerprint(_valueOf(entry.key)) == entry.value) {
          await _dirty.delete(entry.key);
        } else {
          kept.add(entry.key);
        }
      }

      _log('push başarılı: ${rows.length} satır yazıldı'
          '${kept.isEmpty ? '' : ', ${kept.length} kayıt push sürerken '
              'değişti, kirli bırakıldı: ${kept.join(', ')}'}');
    } on PostgrestException catch (e) {
      // Sunucu cevap verdi ama reddetti — RLS, şema uyuşmazlığı, kısıt ihlali.
      _log('push REDDEDİLDİ: code=${e.code} message=${e.message} '
          'details=${e.details} hint=${e.hint}');
    } catch (e) {
      // Ağ/DNS/TLS gibi sunucuya ulaşamama durumları.
      // Kirli işaretler duruyor; bağlantı gelince tekrar denenir.
      _log('push BAŞARISIZ (${e.runtimeType}): $e');
    }
  }

  Future<void> pull() async {
    if (_client.auth.currentUser == null) {
      _log('pull atlandı: oturum yok');
      return;
    }

    final since = _meta.get(_cursorKey) as String? ?? '1970-01-01T00:00:00Z';

    try {
      final rows = await _client
          .from('records')
          .select('collection, key, data, deleted, updated_at')
          .gt('updated_at', since)
          .order('updated_at');

      for (final row in rows) {
        final collection = row['collection'] as String;
        final boxName = collections[collection];
        if (boxName == null) continue;

        final key = row['key'] as String;
        final box = Hive.box(boxName);

        _suppressed.add('$collection|$key');
        if (row['deleted'] == true || row['data'] == null) {
          await box.delete(key);
        } else {
          await box.put(key, Map<String, dynamic>.from(row['data'] as Map));
        }
      }

      if (rows.isNotEmpty) {
        await _meta.put(_cursorKey, rows.last['updated_at'] as String);
      }
      _log('pull tamam: ${rows.length} satır (since=$since)');
    } on PostgrestException catch (e) {
      _log('pull REDDEDİLDİ: code=${e.code} message=${e.message} '
          'details=${e.details} hint=${e.hint}');
    } catch (e) {
      _log('pull BAŞARISIZ (${e.runtimeType}): $e');
    }
  }

  /// `'collection|key'` -> kutudaki güncel değer. Kayıt silinmişse ya da kutu
  /// tanınmıyorsa null; parmak izi karşılaştırması için ikisini ayırmak gerekmez.
  dynamic _valueOf(String id) {
    final sep = id.indexOf('|');
    if (sep < 0) return null;
    final boxName = collections[id.substring(0, sep)];
    if (boxName == null) return null;
    return Hive.box(boxName).get(id.substring(sep + 1));
  }

  /// Bir değerin "aynı mı" karşılaştırması için düz metin özeti. Hive iç içe
  /// `Map`/`List` döndürdüğü için `==` çalışmaz. Değerler zaten jsonb'ye
  /// gönderildiği için kodlanabilir olmaları garanti.
  static String _fingerprint(dynamic value) => jsonEncode(_jsonSafe(value));

  /// Hive `Map<dynamic, dynamic>` döndürür; jsonb'ye gitmeden önce tiplendirilir.
  static dynamic _jsonSafe(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _jsonSafe(v)));
    }
    if (value is List) return value.map(_jsonSafe).toList();
    return value;
  }
}
