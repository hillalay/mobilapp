import 'package:flutter/material.dart';

class NotesCard extends StatelessWidget {
  const NotesCard({
    super.key,
    required this.controller,
    this.onChanged,
    this.title = 'NOTES',
    this.hintText = 'Bugün için not...',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String title;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const borderColor = Color(0xFF2C2C2C);
    const cardBg = Color(0xFFFFF4E9);
    const starColor = Color(0xFFFFD34D);
    const starStroke = Color(0xFF2C2C2C);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ✅ Bu Column ölçüyü garanti eder
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                  color: borderColor,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: borderColor.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: borderColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        // ⭐ yıldızlar: absolute konum
        const _Star(top: -6, left: 6, size: 26, fill: starColor, stroke: starStroke),
        const _Star(top: -12, right: 6, size: 30, fill: starColor, stroke: starStroke),
        const _Star(top: 78, right: -8, size: 56, fill: starColor, stroke: starStroke),
        const _Star(top: 168, left: 18, size: 22, fill: starColor, stroke: starStroke),
        const _Star(top: 168, right: 26, size: 16, fill: starColor, stroke: starStroke),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.size,
    required this.fill,
    required this.stroke,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double size;
  final Color fill;
  final Color stroke;
  final double? top, left, right, bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.star, size: size + 6, color: stroke),
          Icon(Icons.star, size: size, color: fill),
        ],
      ),
    );
  }
}
