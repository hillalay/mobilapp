import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/auth_providers.dart';
import '../exams/exam_providers.dart';
import '../leaderboard/leaderboard_page.dart' show myWeeklyRankProvider;
import '../timer/daily_study_stats_providers.dart';
import 'profile_controller.dart';

const _avatarBucket = 'avatars';

/// Yüklenen görselin sınırları. Liderlik tablosunda 36px gösteriliyor,
/// ücretsiz planda depolama kotası da dar.
const _maxAvatarPx = 512;
const _avatarQuality = 80;

/// image_cropper'ın yerel kırpma ekranı yalnızca mobilde var; masaüstünde
/// çağrılırsa MissingPluginException atar.
bool get _cropSupported => Platform.isAndroid || Platform.isIOS;

/// Kendi profil fotoğrafının adresi. Yükleme sonrası invalidate ediliyor.
final myAvatarUrlProvider = FutureProvider<String?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (client == null || user == null) return null;

  final row = await client
      .from('profiles')
      .select('avatar_url')
      .eq('user_id', user.id)
      .maybeSingle();

  return row?['avatar_url'] as String?;
});

class IdentityCard extends ConsumerStatefulWidget {
  const IdentityCard({super.key});

  @override
  ConsumerState<IdentityCard> createState() => _IdentityCardState();
}

class _IdentityCardState extends ConsumerState<IdentityCard> {
  bool _busy = false;

  /// Kare kırpma ekranı. Kullanıcı yakınlaştırıp kaydırarak hangi bölgenin
  /// görüneceğini seçiyor. İptal ederse null döner.
  Future<CroppedFile?> _crop(String sourcePath) {
    return ImageCropper().cropImage(
      sourcePath: sourcePath,
      // Profil fotoğrafı dairesel gösterildiği için oran 1:1'e kilitli.
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      maxWidth: _maxAvatarPx,
      maxHeight: _maxAvatarPx,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: _avatarQuality,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Fotoğrafı kırp',
          lockAspectRatio: true,
          // Alt kontroller açık: yakınlaştırma/döndürme sekmeleri görünsün.
          // Oran yine kilitli, tek preset kare.
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Fotoğrafı kırp',
          doneButtonTitle: 'Tamam',
          cancelButtonTitle: 'Vazgeç',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
          cropStyle: CropStyle.circle,
        ),
      ],
    );
  }

  Future<void> _pickAndUpload() async {
    final client = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);
    if (client == null || user == null) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Kırpma yapılacaksa tam çözünürlükte al: önce küçültmek, sonra küçük bir
      // bölgeyi kırpmak bulanık sonuç verirdi. Küçültme kırpma çıktısına
      // uygulanıyor. Masaüstünde kırpma olmadığı için burada uygulanıyor.
      maxWidth: _cropSupported ? null : _maxAvatarPx.toDouble(),
      maxHeight: _cropSupported ? null : _maxAvatarPx.toDouble(),
      imageQuality: _cropSupported ? null : _avatarQuality,
    );
    if (picked == null) return;

    var sourcePath = picked.path;

    if (_cropSupported) {
      final cropped = await _crop(picked.path);
      // İptal/geri: hiçbir yükleme yapılmıyor, eski fotoğraf duruyor.
      if (cropped == null) return;
      sourcePath = cropped.path;
    }

    setState(() => _busy = true);
    try {
      final path = '${user.id}/avatar.jpg';

      await client.storage.from(_avatarBucket).upload(
            path,
            File(sourcePath),
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      // Public URL sabit; tarayıcı/Flutter önbelleğini atlatmak için sürüm ekle.
      final url = client.storage.from(_avatarBucket).getPublicUrl(path);
      final versioned = '$url?v=${DateTime.now().millisecondsSinceEpoch}';

      await client
          .from('profiles')
          .update({'avatar_url': versioned}).eq('user_id', user.id);

      ref.invalidate(myAvatarUrlProvider);

      // Onay geri bildirimi: fotoğrafın kendisi değişiyor, SnackBar yok.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf yüklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  static String _fmtHours(int seconds) {
    final h = seconds ~/ 3600;
    if (h > 0) return '${h}sa';
    return '${(seconds % 3600) ~/ 60}dk';
  }

  static const _trackLabels = {
    Track.mf: 'MF',
    Track.tm: 'TM',
    Track.sozel: 'Sözel',
    Track.dil: 'Dil',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final username = (user.userMetadata?['username'] as String?) ?? '';
    final avatarUrl = ref.watch(myAvatarUrlProvider).value;
    final profile = ref.watch(profileProvider).value;
    final rank = ref.watch(myWeeklyRankProvider).value;
    final examCount = ref.watch(examsProvider).value?.length;

    // "alan · günlük hedef" — tasarımdaki "alan · yıl" için yıl verisi yok.
    final track = profile == null ? null : _trackLabels[profile.track];
    final goal = profile?.dailyGoalHours;
    final subtitle = [
      if (track != null) track,
      if (goal != null) 'Günde $goal saat',
    ].join(' · ');

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF17171A),
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -18,
            child: Mascot(size: 104, swing: false, opacity: 0.16),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _busy ? null : _pickAndUpload,
                      child: _SquareAvatar(
                        username: username,
                        url: avatarUrl,
                        busy: _busy,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username.isEmpty ? 'Kullanıcı' : username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.display(21, const Color(0xFFF7F3EE),
                                tracking: -0.02),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(subtitle,
                                style: AppTheme.ui(12.5, const Color(0xFF8B8378))),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _Stat(
                      value: rank == null ? '—' : '#$rank',
                      label: 'Haftalık sıra',
                      color: c.pencil,
                    ),
                    const SizedBox(width: 20),
                    _Stat(
                      value: ref.watch(_totalStudyProvider).maybeWhen(
                            data: _fmtHours,
                            orElse: () => '—',
                          ),
                      label: 'Toplam süre',
                      color: const Color(0xFFF7F3EE),
                    ),
                    const SizedBox(width: 20),
                    _Stat(
                      value: examCount == null ? '—' : '$examCount',
                      label: 'Deneme',
                      color: const Color(0xFFF7F3EE),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _totalStudyProvider = FutureProvider<int>((ref) async {
  return ref.read(dailyStatsStorageProvider).loadTotalSeconds();
});

/// Kimlik kartındaki 62×62 kare avatar. Dokununca fotoğraf seçimi açılır.
class _SquareAvatar extends StatelessWidget {
  const _SquareAvatar({required this.username, this.url, this.busy = false});

  final String username;
  final String? url;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final brand = context.colors.brand;

    return Container(
      width: 62,
      height: 62,
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: brand,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null && url!.isNotEmpty)
            Image.network(url!, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          if (url == null || url!.isEmpty)
            Center(
              child: Text(
                username.isEmpty ? '?' : username.characters.first.toUpperCase(),
                style: AppTheme.display(26, const Color(0xFF17171A), tracking: -0.02),
              ),
            ),
          if (busy)
            const ColoredBox(
              color: Color(0x8817171A),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTheme.display(19, color, tracking: -0.02)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.ui(11, const Color(0xFF8B8378))),
      ],
    );
  }
}
