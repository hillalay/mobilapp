import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_providers.dart';
import '../../core/study_presence.dart';
import '../profile/avatar_section.dart' show AvatarCircle;

enum LeaderboardRange {
  today('v_leaderboard_today', 'Günlük'),
  week('v_leaderboard_week', 'Haftalık');

  const LeaderboardRange(this.view, this.label);

  final String view;
  final String label;
}

class LeaderboardRow {
  const LeaderboardRow({
    required this.username,
    required this.stopwatchSeconds,
    this.avatarUrl,
  });

  final String username;
  final String? avatarUrl;

  /// Sadece kronometreyle ölçülen süre; manuel girişler sıralamaya girmiyor.
  final int stopwatchSeconds;

  /// "2 sa 15 dk"
  String get formatted {
    final hours = stopwatchSeconds ~/ 3600;
    final minutes = (stopwatchSeconds % 3600) ~/ 60;
    return '$hours sa $minutes dk';
  }
}

final leaderboardProvider = FutureProvider.autoDispose
    .family<List<LeaderboardRow>, LeaderboardRange>((ref, range) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const [];

  final rows = await client
      .from(range.view)
      .select('username, avatar_url, stopwatch_seconds')
      .order('stopwatch_seconds', ascending: false)
      .limit(100);

  return rows
      .map((r) => LeaderboardRow(
            username: r['username'] as String,
            avatarUrl: r['avatar_url'] as String?,
            stopwatchSeconds: (r['stopwatch_seconds'] as num?)?.toInt() ?? 0,
          ))
      .toList();
});

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  /// Sayfaya özel kanal: sadece burası açıkken yaşıyor.
  RealtimeChannel? _changes;
  Timer? _poll;
  StudyPresence? _presence;

  /// dispose() içinde ref.read çağırmak güvenli değil; istemci burada tutuluyor.
  SupabaseClient? _client;

  LeaderboardRange _range = LeaderboardRange.today;

  @override
  void initState() {
    super.initState();
    // Provider'lar initState'te ref.read ile okunabilir; abonelikler ilk
    // kareden sonra kuruluyor.
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  void _subscribe() {
    if (!mounted) return;

    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    _client = client;

    _presence = ref.read(studyPresenceProvider);
    _presence?.addWatcher();
    _presence?.activeUsernames.addListener(_onPresenceChanged);

    // records üzerindeki RLS realtime'da da geçerli: bu abonelik yalnızca
    // KENDİ satırlarımızın değişimini iletir. Başkalarının süreleri için
    // aşağıdaki periyodik yenileme gerekiyor.
    _changes = client.channel('leaderboard-changes')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'records',
        callback: (_) => _refresh(),
      )
      ..subscribe();

    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  void _onPresenceChanged() {
    if (mounted) setState(() {});
  }

  void _refresh() {
    if (mounted) ref.invalidate(leaderboardProvider(_range));
  }

  @override
  void dispose() {
    // Sayfadan çıkınca tüm realtime dinleyicileri kapanıyor.
    _poll?.cancel();
    _presence?.activeUsernames.removeListener(_onPresenceChanged);
    _presence?.removeWatcher();

    final channel = _changes;
    if (channel != null) {
      _changes = null;
      _client?.removeChannel(channel);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(leaderboardProvider(_range));
    final myUsername =
        ref.watch(currentUserProvider)?.userMetadata?['username'] as String?;
    final active = _presence?.activeUsernames.value ?? const <String>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liderlik Tablosu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _refresh,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<LeaderboardRange>(
              segments: [
                for (final r in LeaderboardRange.values)
                  ButtonSegment(value: r, label: Text(r.label)),
              ],
              selected: {_range},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _range = s.first),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Message(
            icon: Icons.cloud_off,
            title: 'Liderlik tablosu yüklenemedi',
            detail: '$e',
            onRetry: _refresh,
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return _Message(
                icon: Icons.emoji_events_outlined,
                title: _range == LeaderboardRange.today
                    ? 'Bugün henüz kimse çalışmamış'
                    : 'Bu hafta henüz kimse çalışmamış',
                detail: 'Kronometreyi başlat, ilk sıra senin olsun.',
              );
            }

            return _AnimatedRankList(
              rows: rows,
              activeUsernames: active,
              myUsername: myUsername,
            );
          },
        ),
      ),
    );
  }
}

/// Sıralama değişince satırlar yeni yerine kayarak gidiyor.
///
/// ponytail: sabit satır yüksekliği + `AnimatedPositioned`. `AnimatedList`
/// yeniden sıralamayı desteklemiyor, hazır paketler de bu iş için fazla.
/// Satır yüksekliği değişken olursa bu yaklaşım yerine ölçüm gerekir.
class _AnimatedRankList extends StatelessWidget {
  const _AnimatedRankList({
    required this.rows,
    required this.activeUsernames,
    required this.myUsername,
  });

  static const rowHeight = 68.0;

  final List<LeaderboardRow> rows;
  final Set<String> activeUsernames;
  final String? myUsername;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: rows.length * rowHeight + 16,
        child: Stack(
          children: [
            for (var i = 0; i < rows.length; i++)
              AnimatedPositioned(
                // Anahtar kullanıcı adı: aynı kişi index değiştirince kayıyor,
                // yeni widget olarak yeniden çizilmiyor.
                key: ValueKey(rows[i].username),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                top: i * rowHeight + 8,
                left: 0,
                right: 0,
                height: rowHeight,
                child: _LeaderboardTile(
                  rank: i + 1,
                  row: rows[i],
                  isActive: activeUsernames.contains(rows[i].username),
                  isMe: myUsername != null && rows[i].username == myUsername,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.row,
    required this.isActive,
    required this.isMe,
  });

  final int rank;
  final LeaderboardRow row;
  final bool isActive;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isMe ? Colors.green.shade50 : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? Colors.green.shade200
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 10),
          AvatarCircle(username: row.username, url: row.avatarUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    row.username,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  const _ActiveDot(),
                ],
              ],
            ),
          ),
          Text(
            row.formatted,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/// "Şu anda çalışıyor" göstergesi.
class _ActiveDot extends StatelessWidget {
  const _ActiveDot();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Şu anda çalışıyor',
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: Colors.green.shade500,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  static const _medals = {
    1: Color(0xFFD4AF37),
    2: Color(0xFF9E9E9E),
    3: Color(0xFFB87333),
  };

  @override
  Widget build(BuildContext context) {
    final color = _medals[rank];

    return SizedBox(
      width: 26,
      child: Text(
        '$rank',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // RefreshIndicator'ın çalışması için kaydırılabilir kalmalı.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            detail,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar dene'),
            ),
          ),
        ],
      ],
    );
  }
}
