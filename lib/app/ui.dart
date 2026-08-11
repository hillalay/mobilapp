import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme.dart';

/// Maskot. [swing] açıkken 4–5 sn'lik sonsuz döngüde yumuşak sallanır:
/// dikeyde 7px, ±2° dönme.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.size = 74,
    this.swing = true,
    this.period = const Duration(milliseconds: 4500),
    this.opacity = 1,
  });

  final double size;
  final bool swing;
  final Duration period;
  final double opacity;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void initState() {
    super.initState();
    if (widget.swing) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final art = Opacity(
      opacity: widget.opacity,
      child: SvgPicture.asset(
        'assets/maskot.svg',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );

    if (!widget.swing) return art;

    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value) * 2 - 1; // -1 … 1
        return Transform.translate(
          offset: Offset(0, t * 3.5),
          child: Transform.rotate(angle: t * 2 * math.pi / 180, child: child),
        );
      },
      child: art,
    );
  }
}

/// Boş durum: maskot + tek satır yönlendirme + tek aksiyon.
/// Gri "Henüz veri yok" metni hiçbir yerde kullanılmaz.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.mascotSize = 64,
    this.compact = false,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double mascotSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Mascot(size: mascotSize),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.ui(13.5, c.inkMuted, height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 6),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Hata: kart içinde tek satır mesaj + "Tekrar dene".
class ErrorLine extends StatelessWidget {
  const ErrorLine({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Row(
      children: [
        Icon(Icons.error_outline, size: 18, color: c.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.ui(13, c.inkMuted),
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
      ],
    );
  }
}

/// Yükleme iskeleti — CircularProgressIndicator yerine aynı ölçüde blok.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 8,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: context.colors.hairline,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Kart: gölge yerine hairline kenarlık. Basılıyken kenarlık marka rengine döner.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    this.radius = AppRadius.card,
    this.color,
    this.border = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final bool border;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color ?? c.surface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: widget.border
            ? Border.all(color: _pressed ? c.brand : c.hairline)
            : null,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

/// Tasarımdaki 25×25 kutucuk: kapalıyken 2px kenarlık, açıkken dolu yeşil + tik.
/// 180ms ölçek animasyonu.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.checked,
    this.size = 25,
    this.onTap,
  });

  final bool checked;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checked ? c.success : Colors.transparent,
          borderRadius: BorderRadius.circular(size * 0.36),
          border: checked ? null : Border.all(color: c.checkboxBorder, width: 2),
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          scale: checked ? 1 : 0,
          child: Icon(Icons.check_rounded,
              size: size * 0.58, color: Colors.white, weight: 700),
        ),
      ),
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
