// DenemeMetre — tema. lib/app/theme.dart olarak koyup app.dart'tan bağla:
//   theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: ThemeMode.system
// Gerekli paket: google_fonts (offline ilk açılış istiyorsan fontları assets/fonts'a al).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  const AppColors({
    required this.brand,
    required this.brandInk,
    required this.brandSoft,
    required this.brandText,
    required this.pencil,
    required this.success,
    required this.danger,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.hairline,
    required this.checkboxBorder,
    required this.barTrack,
  });

  final Color brand, brandInk, brandSoft, brandText, pencil, success, danger;
  final Color background, surface, surfaceAlt;
  final Color ink, inkMuted, inkFaint, hairline, checkboxBorder, barTrack;

  static const light = AppColors(
    brand: Color(0xFFF98B3C),
    brandInk: Color(0xFFFFFFFF),
    brandSoft: Color(0xFFFFEEDD),
    brandText: Color(0xFFC2620F),
    pencil: Color(0xFFFFD666),
    success: Color(0xFF0E9F6E),
    danger: Color(0xFFE0603F),
    background: Color(0xFFFFF6EE),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFFFFFF),
    ink: Color(0xFF17171A),
    inkMuted: Color(0xFF8A8179),
    inkFaint: Color(0xFFB0A79E),
    hairline: Color(0x1417171A),
    checkboxBorder: Color(0x2917171A),
    barTrack: Color(0xFFFFD9B8),
  );

  static const dark = AppColors(
    brand: Color(0xFFF98B3C),
    brandInk: Color(0xFF17171A),
    brandSoft: Color(0x24F98B3C),
    brandText: Color(0xFFF98B3C),
    pencil: Color(0xFFFFD666),
    success: Color(0xFF0E9F6E),
    danger: Color(0xFFE0603F),
    background: Color(0xFF121215),
    surface: Color(0xFF1B1B21),
    surfaceAlt: Color(0xFF1A1A1F),
    ink: Color(0xFFF7F3EE),
    inkMuted: Color(0xFF8B8378),
    inkFaint: Color(0xFF6F675F),
    hairline: Color(0x12FFFFFF),
    checkboxBorder: Color(0x33FFFFFF),
    barTrack: Color(0xFF3A2E23),
  );

  /// Isı haritası rampası: açık -> yoğun.
  static const heat = [
    Color(0xFFF5F0EA),
    Color(0xFFFFEEDD),
    Color(0xFFFBC894),
    Color(0xFFF98B3C),
    Color(0xFFD9600C),
  ];
}

/// context.colors ile her yerden erişilir.
class AppColorsExt extends ThemeExtension<AppColorsExt> {
  const AppColorsExt(this.c);
  final AppColors c;

  @override
  ThemeExtension<AppColorsExt> copyWith({AppColors? c}) => AppColorsExt(c ?? this.c);

  @override
  ThemeExtension<AppColorsExt> lerp(ThemeExtension<AppColorsExt>? other, double t) => this;
}

extension AppColorsOn on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColorsExt>()!.c;
}

class AppRadius {
  static const chip = 999.0;
  static const check = 9.0;
  static const row = 17.0;
  static const button = 18.0;
  static const card = 22.0;
  static const hero = 28.0;
  static const sheet = 30.0;
}

class AppSpace {
  static const gutter = 22.0;
  static const gutterWide = 26.0;
  static const rowGap = 9.0;
  static const cardGap = 10.0;
  static const blockGap = 20.0;
  static const sectionGap = 24.0;
}

class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  /// Bricolage Grotesque w800 — başlıklar ve sayısal değerler.
  static TextStyle display(double size, Color color, {double tracking = -0.03}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: size * tracking,
        color: color,
      );

  /// DM Sans — arayüz metni.
  static TextStyle ui(double size, Color color,
          {FontWeight weight = FontWeight.w400, double height = 1.35}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
      );

  static TextStyle caps(Color color) => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: color,
      );

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.brandInk,
      primaryContainer: c.brandSoft,
      onPrimaryContainer: c.brandText,
      secondary: c.pencil,
      onSecondary: const Color(0xFF17171A),
      error: c.danger,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      outline: c.hairline,
      outlineVariant: c.hairline,
    );

    final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.hairline,
      splashColor: c.brand.withValues(alpha: 0.08),
      highlightColor: c.brand.withValues(alpha: 0.05),
      extensions: [AppColorsExt(c)],
      textTheme: TextTheme(
        displaySmall: display(30, c.ink),
        headlineMedium: display(24, c.ink, tracking: -0.02),
        headlineSmall: display(21, c.ink, tracking: -0.02),
        titleLarge: GoogleFonts.bricolageGrotesque(
            fontSize: 16, fontWeight: FontWeight.w700, color: c.ink),
        titleMedium: ui(14.5, c.ink, weight: FontWeight.w700),
        bodyLarge: ui(14.5, c.ink, height: 1.5),
        bodyMedium: ui(13, c.inkMuted, height: 1.45),
        bodySmall: ui(12, c.inkMuted),
        labelLarge: ui(15, c.ink, weight: FontWeight.w700),
        labelMedium: ui(12, c.brandText, weight: FontWeight.w700),
        labelSmall: ui(10, c.inkFaint, weight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: c.ink),
        titleTextStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 21, fontWeight: FontWeight.w800, color: c.ink, letterSpacing: -0.4),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: c.hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.brandInk,
          minimumSize: const Size.fromHeight(52),
          textStyle: ui(15, c.brandInk, weight: FontWeight.w700),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: c.hairline),
          textStyle: ui(14, c.ink, weight: FontWeight.w700),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.brandText,
          textStyle: ui(13, c.brandText, weight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: ui(14, c.inkFaint),
        labelStyle: ui(11, c.inkFaint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.brand, width: 1.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.success : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: c.checkboxBorder, width: 2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.check)),
        visualDensity: VisualDensity.compact,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.success : c.checkboxBorder),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surfaceAlt,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 70,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 23,
              color: s.contains(WidgetState.selected) ? c.brand : c.inkFaint,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => ui(
              10,
              s.contains(WidgetState.selected) ? c.brand : c.inkFaint,
              weight: FontWeight.w700,
            )),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: const Color(0x6B17171A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        titleTextStyle: display(20, c.ink, tracking: -0.02),
        contentTextStyle: ui(14, c.inkMuted, height: 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: ui(13.5, c.background, weight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.brandSoft,
        side: BorderSide.none,
        labelStyle: ui(12, c.brandText, weight: FontWeight.w700),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.brand,
        linearTrackColor: c.hairline,
      ),
    );
  }
}
