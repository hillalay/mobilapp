import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_providers.dart';

/// "Şu anda çalışanlar" — Supabase Realtime Presence.
///
/// Tek bir `active-studiers` kanalı iki farklı tarafça kullanılıyor:
///   * Kronometre kendi durumunu **yayınlıyor** (track/untrack)
///   * Liderlik tablosu başkalarınınkini **dinliyor**
///
/// İkisi aynı topic'e ayrı ayrı abone olamaz, o yüzden kanal burada tek
/// noktada tutuluyor ve referans sayımıyla yönetiliyor: kronometre çalışıyorsa
/// ya da liderlik sayfası açıksa kanal açık kalır, ikisi de bitince kapanır.
class StudyPresence {
  StudyPresence(this._client);

  static const channelName = 'active-studiers';

  final SupabaseClient _client;

  RealtimeChannel? _channel;
  bool _studying = false;
  int _watchers = 0;

  /// Şu anda çalışan kullanıcı adları. Liderlik tablosu bunu dinliyor.
  final activeUsernames = ValueNotifier<Set<String>>(<String>{});

  bool get _needsChannel => _studying || _watchers > 0;

  Future<void> _ensureChannel() async {
    if (_channel != null) return;

    final channel = _client.channel(
      channelName,
      opts: const RealtimeChannelConfig(self: true),
    );
    _channel = channel;

    channel
        .onPresenceSync((_) => _readState())
        .onPresenceJoin((_) => _readState())
        .onPresenceLeave((_) => _readState())
        .subscribe();
  }

  void _readState() {
    final channel = _channel;
    if (channel == null) return;

    final names = <String>{};
    for (final state in channel.presenceState()) {
      for (final presence in state.presences) {
        final username = presence.payload['username'] as String?;
        if (username != null && username.isNotEmpty) names.add(username);
      }
    }
    activeUsernames.value = names;
  }

  /// Kronometre başlayınca true, duraklayınca/durunca false.
  Future<void> setStudying(bool studying) async {
    if (_studying == studying) return;
    _studying = studying;

    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      if (studying) {
        await _ensureChannel();
        await _channel?.track({
          'user_id': user.id,
          'username': user.userMetadata?['username'] ?? '',
        });
      } else {
        await _channel?.untrack();
        await _closeIfIdle();
      }
    } catch (e) {
      debugPrint('presence setStudying($studying) başarısız: $e');
    }
  }

  /// Liderlik sayfası açıldığında çağrılır.
  Future<void> addWatcher() async {
    _watchers++;
    try {
      await _ensureChannel();
      _readState();
    } catch (e) {
      debugPrint('presence addWatcher başarısız: $e');
    }
  }

  /// Liderlik sayfasının dispose'unda çağrılır.
  Future<void> removeWatcher() async {
    if (_watchers > 0) _watchers--;
    await _closeIfIdle();
  }

  Future<void> _closeIfIdle() async {
    if (_needsChannel || _channel == null) return;
    final channel = _channel;
    _channel = null;
    activeUsernames.value = <String>{};
    try {
      await _client.removeChannel(channel!);
    } catch (e) {
      debugPrint('presence kanalı kapatılamadı: $e');
    }
  }

  Future<void> dispose() async {
    _studying = false;
    _watchers = 0;
    await _closeIfIdle();
    activeUsernames.dispose();
  }
}

final studyPresenceProvider = Provider<StudyPresence?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;

  final presence = StudyPresence(client);
  ref.onDispose(presence.dispose);
  return presence;
});
