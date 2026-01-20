import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_controller.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  UserRole? role;
  GradeGroup? gradeGroup;
  Track? track;

  @override
  Widget build(BuildContext context) {
    final canContinue = role != null &&
        (role == UserRole.university ||
            (role == UserRole.highSchool &&
                gradeGroup != null &&
                (gradeGroup == GradeGroup.g9_10 || track != null)));

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Kurulumu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Önce profilini seçelim:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),

            // Rol
            _sectionTitle('Kullanıcı tipi'),
            RadioListTile<UserRole>(
              value: UserRole.highSchool,
              groupValue: role,
              title: const Text('Lise öğrencisiyim'),
              onChanged: (v) => setState(() {
                role = v;
                gradeGroup = null;
                track = null;
              }),
            ),
            RadioListTile<UserRole>(
              value: UserRole.university,
              groupValue: role,
              title: const Text('Üniversite öğrencisiyim'),
              onChanged: (v) => setState(() {
                role = v;
                gradeGroup = null;
                track = null;
              }),
            ),

            const SizedBox(height: 12),

            // Lise detayları
            if (role == UserRole.highSchool) ...[
              _sectionTitle('Sınıf grubu'),
              RadioListTile<GradeGroup>(
                value: GradeGroup.g9_10,
                groupValue: gradeGroup,
                title: const Text('9-10. sınıf'),
                onChanged: (v) => setState(() {
                  gradeGroup = v;
                  track = null;
                }),
              ),
              RadioListTile<GradeGroup>(
                value: GradeGroup.g11_12,
                groupValue: gradeGroup,
                title: const Text('11-12. sınıf (Sınav öğrencisi)'),
                onChanged: (v) => setState(() {
                  gradeGroup = v;
                  track = null;
                }),
              ),

              if (gradeGroup == GradeGroup.g11_12) ...[
                const SizedBox(height: 12),
                _sectionTitle('Alan'),
                DropdownButtonFormField<Track>(
                  value: track,
                  items: const [
                    DropdownMenuItem(value: Track.tm, child: Text('TM')),
                    DropdownMenuItem(value: Track.mf, child: Text('MF')),
                    DropdownMenuItem(value: Track.dil, child: Text('Dil')),
                    DropdownMenuItem(value: Track.sozel, child: Text('Sözel')),
                  ],
                  onChanged: (v) => setState(() => track = v),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Alan seç',
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),
            FilledButton(
              onPressed: canContinue
                  ? () async{
                      final profile = UserProfile(
                        role: role!,
                        gradeGroup: gradeGroup,
                        track: track,
                      );
                      await ref.read(profileProvider.notifier).setProfile(profile);
                      if(context.mounted) context.go('/dashboard');
                    }
                  : null,
              child: const Text('Devam'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
