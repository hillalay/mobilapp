import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import 'profile_controller.dart';

/// Onboarding her iki temada da koyudur (tam ekran karşılama).
const _bg = Color(0xFF17171A);
const _rowBg = Color(0xFF1E1E24);
const _rowBgPressed = Color(0xFF24242B);
const _ink = Color(0xFFF7F3EE);
const _inkFaint = Color(0xFF6F675F);
const _brand = Color(0xFFF98B3C);
const _pencil = Color(0xFFFFD666);

class _Choice {
  const _Choice(this.code, this.label);
  final String code;
  final String label;
}

class _Step {
  const _Step(this.bubble, this.title, this.choices);
  final String bubble;
  final String title;
  final List<_Choice> choices;
}

/// Seçenekler profile_controller.dart'ta tek kaynakta; profil ayarları da
/// aynı listeyi kullanıyor.
final _steps = <_Step>[
  _Step('Merhaba! Ben Metre.', 'Hangi alanda yarışıyorsun?', [
    for (final e in trackChoices.entries) _Choice(e.value.$1, e.value.$2),
  ]),
  _Step('Güzel seçim.', 'Günde kaç saat hedefliyorsun?', [
    for (final e in goalHourChoices.entries) _Choice(e.value.$1, e.value.$2),
  ]),
  _Step('Son bir şey…', 'Seni ne zaman dürtelim?', [
    for (final e in reminderChoices.entries) _Choice(e.value.$1, e.value.$2),
  ]),
];

final _tracks = trackChoices.keys.toList();
final _goalHourOptions = goalHourChoices.keys.toList();
final _reminderHourOptions = reminderChoices.keys.toList();

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;
  Track? _track;
  int? _goalHours;
  int? _reminderHour;
  bool _saving = false;

  Future<void> _pick(int index) async {
    switch (_step) {
      case 0:
        _track = _tracks[index];
      case 1:
        _goalHours = _goalHourOptions[index];
      case 2:
        _reminderHour = _reminderHourOptions[index];
    }

    if (_step < _steps.length - 1) {
      setState(() => _step++);
      return;
    }

    setState(() => _saving = true);

    // Adım 1 bugünkü davranışı koruyor: profil Track ile oluşturuluyor.
    await ref.read(profileProvider.notifier).setProfile(
          UserProfile(
            track: _track ?? Track.mf,
            dailyGoalHours: _goalHours,
            reminderHour: _reminderHour,
          ),
        );

    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADIM ${_step + 1} / ${_steps.length}',
                style: AppTheme.ui(11, _inkFaint, weight: FontWeight.w700)
                    .copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 34),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Mascot(size: 88, period: Duration(milliseconds: 4200)),
                  const SizedBox(width: 12),
                  Flexible(child: _Bubble(text: step.bubble)),
                ],
              ),
              const SizedBox(height: 36),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey(_step),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: AppTheme.display(30, _ink).copyWith(
                            letterSpacing: -0.9,
                          ),
                        ),
                        const SizedBox(height: 24),
                        for (var i = 0; i < step.choices.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _ChoiceRow(
                            choice: step.choices[i],
                            onTap: _saving ? null : () => _pick(i),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              _StepDots(count: _steps.length, active: _step),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: const BoxDecoration(
          color: _pencil,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(5),
          ),
        ),
        child: Text(
          text,
          style: AppTheme.ui(15, const Color(0xFF17171A), weight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatefulWidget {
  const _ChoiceRow({required this.choice, this.onTap});

  final _Choice choice;
  final VoidCallback? onTap;

  @override
  State<_ChoiceRow> createState() => _ChoiceRowState();
}

class _ChoiceRowState extends State<_ChoiceRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _pressed ? _rowBgPressed : _rowBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _pressed ? _brand : const Color(0x14FFFFFF),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0x29F98B3C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.choice.code,
                style: AppTheme.display(14, _brand, tracking: -0.02),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.choice.label,
                style: AppTheme.ui(15, _ink, weight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right, color: _inkFaint, size: 22),
          ],
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == active ? 26 : 9,
            height: 5,
            decoration: BoxDecoration(
              color: i == active ? _brand : const Color(0x2EFFFFFF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    );
  }
}
