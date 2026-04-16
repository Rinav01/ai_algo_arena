import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ─── "Neural Arena" Design System (Generated via Google Stitch) ─────────────
/// Creative North Star: "The Neural Nexus" — a high-performance HUD where
/// data feels alive. Intentional asymmetry, tonal depth, technical elegance.
///
/// Background: #0E1322  Surfaces: layered container tiers.
/// Accent:     #8B5CF6  (violet secondary)
/// Tertiary:   #00DBE9  (cyan — used for paths, health bars, active states)
/// Fonts:      Space Grotesk (headings) + Manrope (body/stats)
/// ─────────────────────────────────────────────────────────────────────────────
abstract class AppTheme {
  // ── Surface Hierarchy (tonal layering, no drop-shadows) ────────────────────
  static const Color background         = Color(0xFF0E1322);
  static const Color surfaceLowest      = Color(0xFF090E1C);
  static const Color surfaceLow         = Color(0xFF161B2B);
  static const Color surface            = Color(0xFF1A1F2F);
  static const Color surfaceHigh        = Color(0xFF25293A);
  static const Color surfaceHighest     = Color(0xFF2F3445);
  static const Color surfaceVariant     = Color(0xFF2F3445);
  static const Color surfaceBright      = Color(0xFF343949);

  // ── Primary palette ────────────────────────────────────────────────────────
  /// Electric violet — gradient start / CTA fill
  static const Color accent             = Color(0xFF8B5CF6);
  /// Deeper violet — gradient end / container background
  static const Color accentContainer    = Color(0xFF571BC1);
  /// Lavender — on-secondary text, chips, labeled stats
  static const Color accentLight        = Color(0xFFD0BCFF);

  // ── Tertiary / Active elements ─────────────────────────────────────────────
  /// Cyan — path cells, health bars, "lit" indicator active states
  static const Color cyan               = Color(0xFF00DBE9);
  static const Color cyanContainer      = Color(0xFF001214);
  static const Color cyanLight          = Color(0xFF7DF4FF);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color onBackground       = Color(0xFFDEE1F7);
  static const Color onSurface         = Color(0xFFDEE1F7);
  static const Color textSecondary      = Color(0xFFC7C6CD);
  static const Color textMuted          = Color(0xFF909097);
  static const Color outline            = Color(0xFF909097);
  static const Color outlineVariant     = Color(0xFF46464C);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success            = Color(0xFF10B981);
  static const Color warning            = Color(0xFFF59E0B);
  static const Color error              = Color(0xFFFFB4AB);
  static const Color errorContainer     = Color(0xFF93000A);

  // ── Grid cell colors ───────────────────────────────────────────────────────
  static const Color cellStart          = Color(0xFF10B981); // emerald — start
  static const Color cellGoal           = Color(0xFFEF4444); // red — goal
  static const Color cellWall           = Color(0xFF1E2A3A); // dark surface
  static const Color cellExplored       = Color(0xFF571BC1); // violet — visited
  static const Color cellPath           = Color(0xFF00DBE9); // cyan — path
  static const Color cellFrontier       = Color(0xFF8B5CF6); // lavender — queue
  static const Color cellWeight         = Color(0xFF166534); // deep green — heavy terrain (forest)
  static const Color cellWeightBorder   = Color(0xFF14532D); 

  // ── Glassmorphism helpers ──────────────────────────────────────────────────

  /// Standard glass card — 60% opacity surface_variant + subtle border
  static BoxDecoration glassCard({
    double radius = 16,
    Color? borderColor,
    Color? glowColor,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: surfaceVariant.withValues(alpha: 0.60),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.08),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.40),
          blurRadius: 40,
          spreadRadius: 0,
        ),
        if (glowColor != null)
          BoxShadow(
            color: glowColor.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: 0,
          ),
      ],
    );
  }

  /// Glass card with violet accent glow.
  static BoxDecoration glassCardAccent({double radius = 16}) => glassCard(
        radius: radius,
        borderColor: accent.withValues(alpha: 0.35),
        glowColor: accent,
      );

  /// "Ghost border" — outline_variant at 15% opacity (accessibility fallback)
  static Border get ghostBorder =>
      Border.all(color: outlineVariant.withValues(alpha: 0.15));

  /// CTA gradient — violet secondary_container → secondary (45°)
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentContainer, accent],
  );

  /// Subtle ambient glow decoration for floating panels
  static BoxDecoration ambientPanel({double radius = 20}) => BoxDecoration(
        color: surfaceVariant.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      );

  // ── Button styles ──────────────────────────────────────────────────────────

  /// Ghost glass button — outlined with ghost border
  static ButtonStyle ghostButton({Color? color}) => OutlinedButton.styleFrom(
        foregroundColor: color ?? accent,
        side: BorderSide(color: (color ?? accent).withValues(alpha: 0.7)),
        backgroundColor: surfaceVariant.withValues(alpha: 0.20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      );

  /// Gradient CTA button wrapper — use inside a Stack/Container
  static BoxDecoration get primaryButtonDecoration => BoxDecoration(
        gradient: ctaGradient,
        borderRadius: BorderRadius.circular(12.r),
      );

  static ButtonStyle primaryButton() => ElevatedButton.styleFrom(
        backgroundColor: accentContainer,
        foregroundColor: const Color(0xFF23005C),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      );

  // ── Flutter ThemeData ──────────────────────────────────────────────────────
  static ThemeData themeData() {
    const textColor = onBackground;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        surface: surface,
        surfaceContainerHighest: surfaceVariant,
        primary: accent,
        primaryContainer: accentContainer,
        onPrimary: const Color(0xFF2B3040),
        secondary: accentLight,
        secondaryContainer: accentContainer,
        onSecondary: const Color(0xFF3C0091),
        tertiary: cyan,
        tertiaryContainer: cyanContainer,
        onTertiary: const Color(0xFF00363A),
        error: error,
        onError: const Color(0xFF690005),
        onSurface: onSurface,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      // ── Typography: Space Grotesk for headings, Manrope for body ───────────
      fontFamily: 'Manrope',
      textTheme: TextTheme(
        // Display / Hero titles  →  Space Grotesk
        displayLarge: TextStyle(
          fontSize: 34.sp,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: -0.6,
          fontFamily: 'SpaceGrotesk',
        ),
        displayMedium: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.4,
          fontFamily: 'SpaceGrotesk',
        ),
        // Section headings  →  Space Grotesk
        headlineLarge: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.w700,
          color: textColor,
          fontFamily: 'SpaceGrotesk',
        ),
        headlineMedium: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFamily: 'SpaceGrotesk',
        ),
        headlineSmall: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFamily: 'SpaceGrotesk',
        ),
        // UI titles  →  Manrope
        titleLarge: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleMedium: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleSmall: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        // Body  →  Manrope
        bodyLarge: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.6.h,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.5.h,
        ),
        bodySmall: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: Color(0xFFC7C6CD),
          height: 1.4.h,
        ),
        // Labels — uppercase caps tags, status indicators
        labelLarge: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 1.0,
          fontFamily: 'SpaceGrotesk',
        ),
        labelMedium: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: accentLight,
          letterSpacing: 1.0,
          fontFamily: 'SpaceGrotesk',
        ),
        labelSmall: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: Color(0xFF909097),
          letterSpacing: 1.2,
          fontFamily: 'SpaceGrotesk',
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: surfaceHighest,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.12),
        trackHeight: 3,
      ),
      iconTheme: const IconThemeData(color: onBackground),
      dividerColor: Colors.white.withValues(alpha: 0.06),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: onBackground,
          fontFamily: 'SpaceGrotesk',
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceVariant.withValues(alpha: 0.95),
        selectedItemColor: accent,
        unselectedItemColor: const Color(0xFF64748B),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentContainer,
          foregroundColor: const Color(0xFF23005C),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          textStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'SpaceGrotesk',
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentLight,
          side: BorderSide(color: accent.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          backgroundColor: surfaceVariant.withValues(alpha: 0.20),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHighest,
        selectedColor: accent.withValues(alpha: 0.25),
        labelStyle: TextStyle(
          fontSize: 12.sp,
          color: onBackground,
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      ),
      cardTheme: CardThemeData(
        color: surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHighest,
        contentTextStyle: const TextStyle(
          color: onBackground,
          fontFamily: 'Manrope',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
