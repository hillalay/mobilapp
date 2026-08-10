import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_providers.dart';

const _avatarBucket = 'avatars';

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

class AvatarSection extends ConsumerStatefulWidget {
  const AvatarSection({super.key});

  @override
  ConsumerState<AvatarSection> createState() => _AvatarSectionState();
}

class _AvatarSectionState extends ConsumerState<AvatarSection> {
  bool _busy = false;

  Future<void> _pickAndUpload() async {
    final client = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);
    if (client == null || user == null) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Yükleme boyutunu sınırla: liderlik tablosunda 36px gösteriliyor,
      // depolama kotası da ücretsiz planda dar.
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      final path = '${user.id}/avatar.jpg';

      await client.storage.from(_avatarBucket).upload(
            path,
            File(picked.path),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profil fotoğrafı güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf yüklenemedi: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final username = (user.userMetadata?['username'] as String?) ?? '';
    final avatarUrl = ref.watch(myAvatarUrlProvider).value;

    return Row(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            AvatarCircle(username: username, url: avatarUrl, radius: 32),
            if (_busy)
              const Positioned.fill(
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username.isEmpty ? 'Kullanıcı' : username,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              if (user.email != null)
                Text(
                  user.email!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickAndUpload,
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(
                  avatarUrl == null ? 'Fotoğraf ekle' : 'Fotoğrafı değiştir',
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fotoğraf yoksa kullanıcı adının baş harfi, ada göre sabit bir renkte.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.username,
    this.url,
    this.radius = 18,
  });

  final String username;
  final String? url;
  final double radius;

  static const palette = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFFFFA726),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFEC407A),
  ];

  static Color colorFor(String username) =>
      palette[username.codeUnits.fold(0, (a, b) => a + b) % palette.length];

  @override
  Widget build(BuildContext context) {
    final color = colorFor(username);
    final initial = Text(
      username.isEmpty ? '?' : username.characters.first.toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: radius * 0.85,
      ),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      // Görsel inemezse baş harfe düşer.
      foregroundImage:
          (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
      child: initial,
    );
  }
}
