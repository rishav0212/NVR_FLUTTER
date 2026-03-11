import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═════════════════════════════════════════════════════════════════════════════
// THEME EXTENSION: DYNAMIC COLORS & GRADIENTS
// ═════════════════════════════════════════════════════════════════════════════
// This allows us to inject custom colors and gradients directly into the
// Flutter Theme, meaning they will automatically switch when the user toggles
// between Light and Dark mode, rather than being stuck as static variables.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color success;
  final Color warning;
  final Color info;
  final LinearGradient bgGradient;
  final RadialGradient meshAmber;
  final RadialGradient meshIndigo;
  final LinearGradient glassSurface;
  final LinearGradient amberTint;
  final Color glassShadowStrong;
  final Color glassShadowSubtle;
  final Color borderSubtle;
  final Color amberGlow10;

  const AppColorsExtension({
    required this.success,
    required this.warning,
    required this.info,
    required this.bgGradient,
    required this.meshAmber,
    required this.meshIndigo,
    required this.glassSurface,
    required this.amberTint,
    required this.glassShadowStrong,
    required this.glassShadowSubtle,
    required this.borderSubtle,
    required this.amberGlow10,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith() => this;

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      bgGradient: LinearGradient.lerp(bgGradient, other.bgGradient, t)!,
      meshAmber: RadialGradient.lerp(meshAmber, other.meshAmber, t)!,
      meshIndigo: RadialGradient.lerp(meshIndigo, other.meshIndigo, t)!,
      glassSurface: LinearGradient.lerp(glassSurface, other.glassSurface, t)!,
      amberTint: LinearGradient.lerp(amberTint, other.amberTint, t)!,
      glassShadowStrong: Color.lerp(
        glassShadowStrong,
        other.glassShadowStrong,
        t,
      )!,
      glassShadowSubtle: Color.lerp(
        glassShadowSubtle,
        other.glassShadowSubtle,
        t,
      )!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      amberGlow10: Color.lerp(amberGlow10, other.amberGlow10, t)!,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SENTINEL DESIGN SYSTEM v4 — "Obsidian & Frost Glass"
// ═════════════════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ── Static Brand Colors (Theme Independent) ────────────────────────────────
  static const Color amber = Color(0xFFE8A020);
  static const Color amberLight = Color(0xFFF5C050);
  static const Color amberDim = Color(0xFFB07818);
  static const Color amberMuted = Color(0xFF7A5210);
  static const Color error = Color(0xFFFF5560);

  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s28 = 28.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s56 = 56.0;
  static const double s64 = 64.0;

  // Legacy aliases
  static const double xs = s4;
  static const double sm = s8;
  static const double md = s16;
  static const double lg = s24;
  static const double xl = s32;
  static const double xxl = s48;

  // ── Radii ─────────────────────────────────────────────────────────────────
  static const double rXs = 4.0;
  static const double rSm = 8.0;
  static const double rMd = 12.0;
  static const double rLg = 18.0;
  static const double rXl = 24.0;
  static const double rFull = 999.0;

  // Legacy aliases
  static const double radiusSm = rSm;
  static const double radiusMd = rMd;
  static const double radiusLg = rLg;
  static const double radiusXl = rXl;

  // ── Animation Timings & Curves ────────────────────────────────────────────
  static const Duration tFast = Duration(milliseconds: 160);
  static const Duration tMid = Duration(milliseconds: 320);
  static const Duration tSlow = Duration(milliseconds: 540);
  static const Duration tXSlow = Duration(milliseconds: 800);

  static const Curve curveEntrance = Curves.easeOutExpo;
  static const Curve curveExit = Curves.easeInCubic;
  static const Curve curveSmooth = Curves.easeInOutCubic;
  static const Curve curveSpring = Curves.elasticOut;

  // ── Shared Gradients ──────────────────────────────────────────────────────
  static const LinearGradient amberBtn = LinearGradient(
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
    colors: [Color(0xFFF5C050), Color(0xFFE8A020), Color(0xFFCC8C18)],
    stops: [0.0, 0.55, 1.0],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME EXTENSION DEFINITIONS (The core of the upgrade)
  // ═══════════════════════════════════════════════════════════════════════════

  /// DARK MODE: Deep cinematic aurora effects, dark cards, deep black shadows.
  static final _darkExt = AppColorsExtension(
    success: const Color(0xFF34D399),
    warning: const Color(0xFFF97316),
    info: const Color(0xFF60A5FA),
    bgGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A0A1E), Color(0xFF060610), Color(0xFF0E0A16)],
      stops: [0.0, 0.55, 1.0],
    ),
    meshAmber: const RadialGradient(
      center: Alignment(-0.7, -0.8),
      radius: 1.1,
      colors: [Color(0x16E8A020), Color(0x00E8A020)],
    ),
    meshIndigo: const RadialGradient(
      center: Alignment(0.8, 1.0),
      radius: 0.9,
      colors: [Color(0x10594FD4), Color(0x00594FD4)],
    ),
    glassSurface: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x18FFFFFF), Color(0x06FFFFFF)],
    ),
    amberTint: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x22E8A020), Color(0x0AE8A020)],
    ),
    glassShadowStrong: Colors.black.withOpacity(0.4),
    glassShadowSubtle: Colors.black.withOpacity(0.2),
    borderSubtle: const Color(0x14FFFFFF),
    amberGlow10: const Color(0x1AE8A020),
  );

  /// LIGHT MODE: Frosted pearl backgrounds, higher opacity meshes for visibility,
  /// and beautiful, soft slate shadows (Apple-style).
  static final _lightExt = AppColorsExtension(
    success: const Color(0xFF10B981),
    warning: const Color(0xFFF59E0B),
    info: const Color(0xFF3B82F6),
    bgGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
      stops: [0.0, 0.55, 1.0],
    ),
    meshAmber: const RadialGradient(
      center: Alignment(-0.7, -0.8),
      radius: 1.1,
      colors: [
        Color(0x28E8A020),
        Color(0x00E8A020),
      ], // Higher opacity for light mode
    ),
    meshIndigo: const RadialGradient(
      center: Alignment(0.8, 1.0),
      radius: 0.9,
      colors: [
        Color(0x22594FD4),
        Color(0x00594FD4),
      ], // Higher opacity for light mode
    ),
    glassSurface: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x80FFFFFF), Color(0x33FFFFFF)], // Brighter frosted glass
    ),
    amberTint: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x33E8A020), Color(0x11E8A020)],
    ),
    glassShadowStrong: const Color(
      0xFF0F172A,
    ).withOpacity(0.08), // Soft slate shadow
    glassShadowSubtle: const Color(
      0xFF0F172A,
    ).withOpacity(0.04), // Very soft slate shadow
    borderSubtle: const Color(0xFFE2E8F0),
    amberGlow10: const Color(0x26E8A020),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Theme Data (Dark) ──────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF060610),
    textTheme: _buildTextTheme(
      primary: const Color(0xFFF0F0FA),
      secondary: const Color(0xFF8080A0),
      hint: const Color(0xFF3A3A58),
    ),
    extensions: [_darkExt],

    // M3 Full Token Coverage
    colorScheme: const ColorScheme.dark(
      primary: amber,
      onPrimary: Color(0xFF060610),
      primaryContainer: amberDim,
      onPrimaryContainer: Color(0xFFF0F0FA),
      secondary: amberLight,
      onSecondary: Color(0xFF060610),
      secondaryContainer: amberMuted,
      onSecondaryContainer: Color(0xFFF0F0FA),
      surface: Color(0xFF0C0C1C),
      onSurface: Color(0xFFF0F0FA),
      surfaceContainer: Color(0xFF111124),
      surfaceContainerHighest: Color(0xFF181830),
      onSurfaceVariant: Color(0xFF8080A0),
      outline: Color(0x14FFFFFF),
      outlineVariant: Color(0x1FFFFFFF),
      error: error,
      onError: Color(0xFF060610),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFF0F0FA),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF8080A0), size: 20),
    ),

    inputDecorationTheme: _buildInputDecoration(
      fillColor: const Color(0xFF111124),
      borderColor: const Color(0x14FFFFFF),
      hintColor: const Color(0xFF3A3A58),
      labelColor: const Color(0xFF8080A0),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: amber,
        textStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0x14FFFFFF),
      thickness: 1,
      space: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF181830),
      contentTextStyle: GoogleFonts.dmSans(
        color: const Color(0xFFF0F0FA),
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(rMd),
        side: const BorderSide(color: Color(0x14FFFFFF)),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
  );

  // ── Theme Data (Light) ─────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    textTheme: _buildTextTheme(
      primary: const Color(0xFF0F172A),
      secondary: const Color(0xFF64748B),
      hint: const Color(0xFF94A3B8),
    ),
    extensions: [_lightExt],

    // M3 Full Token Coverage
    colorScheme: const ColorScheme.light(
      primary: amberDim, // Deeper amber for contrast
      onPrimary: Colors.white,
      primaryContainer: amberLight,
      onPrimaryContainer: Color(0xFF0F172A),
      secondary: amber,
      onSecondary: Colors.white,
      secondaryContainer: amberLight,
      onSecondaryContainer: Color(0xFF0F172A),
      surface: Colors.white,
      onSurface: Color(0xFF0F172A),
      surfaceContainer: Colors.white,
      surfaceContainerHighest: Color(0xFFF1F5F9),
      onSurfaceVariant: Color(0xFF64748B),
      outline: Color(0xFFE2E8F0),
      outlineVariant: Color(0xFFCBD5E1),
      error: error,
      onError: Colors.white,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF64748B), size: 20),
    ),

    inputDecorationTheme: _buildInputDecoration(
      fillColor: Colors.white,
      borderColor: const Color(0xFFE2E8F0),
      hintColor: const Color(0xFF94A3B8),
      labelColor: const Color(0xFF64748B),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: amberDim,
        textStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
      space: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1E293B), // Slate 800
      contentTextStyle: GoogleFonts.dmSans(
        color: const Color(0xFFF8F9FA),
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS & DECORATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Dynamic Text Theme Generator
  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
    required Color hint,
  }) => TextTheme(
    displayLarge: GoogleFonts.outfit(
      fontSize: 38,
      fontWeight: FontWeight.w700,
      color: primary,
      letterSpacing: -1.5,
      height: 1.05,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: primary,
      letterSpacing: -0.8,
      height: 1.1,
    ),
    displaySmall: GoogleFonts.outfit(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: -0.4,
    ),
    headlineLarge: GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: -0.3,
    ),
    headlineMedium: GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: -0.1,
    ),
    headlineSmall: GoogleFonts.outfit(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: primary,
      height: 1.6,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: secondary,
      height: 1.55,
    ),
    bodySmall: GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: hint,
      height: 1.45,
    ),
    labelLarge: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: secondary,
      letterSpacing: 0.2,
    ),
    labelSmall: GoogleFonts.dmSans(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: hint,
      letterSpacing: 0.5,
    ),
  );

  /// Dynamic Input Decoration Generator
  static InputDecorationTheme _buildInputDecoration({
    required Color fillColor,
    required Color borderColor,
    required Color hintColor,
    required Color labelColor,
  }) => InputDecorationTheme(
    filled: true,
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: s16, vertical: 18.0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(rMd),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(rMd),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(rMd),
      borderSide: const BorderSide(color: amber, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(rMd),
      borderSide: const BorderSide(color: error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(rMd),
      borderSide: const BorderSide(color: error, width: 1.5),
    ),
    hintStyle: GoogleFonts.dmSans(color: hintColor, fontSize: 14),
    labelStyle: GoogleFonts.dmSans(color: labelColor, fontSize: 14),
    floatingLabelStyle: GoogleFonts.dmSans(color: amber, fontSize: 12),
    prefixIconColor: hintColor,
    suffixIconColor: hintColor,
    errorStyle: GoogleFonts.dmSans(color: error, fontSize: 11),
  );

  // ── Context-Aware Decorators ──────────────────────────────────────────────
  // Automatically pull the correct meshes, glass, and shadows based on mode!

  /// Glass card decoration — Frosted surface with responsive soft shadows
  static BoxDecoration glassCard(
    BuildContext context, {
    double? radius,
    Color? borderColor,
    bool addShadow = true,
  }) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    return BoxDecoration(
      gradient: ext.glassSurface,
      borderRadius: BorderRadius.circular(radius ?? rLg),
      border: Border.all(color: borderColor ?? ext.borderSubtle, width: 1),
      boxShadow: addShadow
          ? [
              BoxShadow(
                color: ext.glassShadowStrong,
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: ext.glassShadowSubtle,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  /// Amber glow container — Context-aware badge background
  static BoxDecoration amberIconBox(
    BuildContext context, {
    double radius = rMd,
  }) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    return BoxDecoration(
      gradient: ext.amberTint,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: amber.withOpacity(0.2)),
      boxShadow: [
        BoxShadow(color: ext.amberGlow10, blurRadius: 16, spreadRadius: 2),
      ],
    );
  }
}
