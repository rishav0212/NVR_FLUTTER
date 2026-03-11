import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SENTINEL DESIGN SYSTEM v3 — "Obsidian Glass"
// ═════════════════════════════════════════════════════════════════════════════
//
// Aesthetic direction: Premium B2B security — deep void blacks, warm amber
// security-light accents, and glass-morphic surfaces that suggest layered
// depth. Inspired by high-end fintech dashboards and aerospace HUDs.
//
// Visual language:
//   • Obsidian void base — deeper than standard dark mode
//   • Mesh gradient bleeds — ambient amber/indigo light on background
//   • Frosted glass cards — translucent surfaces with inner light rim
//   • Amber as the ONLY accent — used with extreme discipline
//   • Cinematic entrance animations — staggered, physics-based, never jarring
//
// RULES:
//   ✓ ALL values live here — zero hardcoding in page/widget files
//   ✓ Named semantically — use surfaceCard, not Color(0xFF...)
//   ✓ Gradients are const — no per-build allocations
// ═════════════════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ── Backgrounds ────────────────────────────────────────────────────────────

  /// Deepest possible background — near void
  static const Color bgBase      = Color(0xFF060610);
  /// Slightly lifted surface — content area base
  static const Color bgSurface   = Color(0xFF0C0C1C);
  /// Card / input fill
  static const Color bgCard      = Color(0xFF111124);
  /// Top-most surface — modals, dropdowns
  static const Color bgElevated  = Color(0xFF181830);

  // ── Borders ────────────────────────────────────────────────────────────────

  static const Color borderSubtle = Color(0x14FFFFFF); // 8%
  static const Color borderMid    = Color(0x1FFFFFFF); // 12%
  static const Color borderAmber  = Color(0x33E8A020); // amber 20%

  // ── Glass overlays (use with Container decoration) ─────────────────────────

  static const Color glassWhite4  = Color(0x0AFFFFFF);
  static const Color glassWhite8  = Color(0x14FFFFFF);
  static const Color glassWhite12 = Color(0x1FFFFFFF);

  // ── Amber family — the ONLY accent ────────────────────────────────────────

  static const Color amber         = Color(0xFFE8A020);
  static const Color amberLight    = Color(0xFFF5C050);
  static const Color amberDim      = Color(0xFFB07818);
  static const Color amberMuted    = Color(0xFF7A5210);

  // Glow / tint variants
  static const Color amberGlow5    = Color(0x0DE8A020);
  static const Color amberGlow10   = Color(0x1AE8A020);
  static const Color amberGlow20   = Color(0x33E8A020);
  static const Color amberGlow35   = Color(0x59E8A020);

  // ── Text ──────────────────────────────────────────────────────────────────

  static const Color textPrimary   = Color(0xFFF0F0FA); // warm white
  static const Color textSecondary = Color(0xFF8080A0); // muted slate
  static const Color textHint      = Color(0xFF3A3A58); // very muted
  static const Color textOnAmber   = Color(0xFF060610); // on filled amber

  // ── Semantic ──────────────────────────────────────────────────────────────

  static const Color success = Color(0xFF34D399);
  static const Color error   = Color(0xFFFF5560);
  static const Color warning = Color(0xFFF97316);
  static const Color info    = Color(0xFF60A5FA);

  // ── Gradients ─────────────────────────────────────────────────────────────

  /// Page base — subtle diagonal darkening
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0A1E), Color(0xFF060610), Color(0xFF0E0A16)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Ambient amber mesh — upper portion bleed (use in Stack)
  static const RadialGradient meshAmber = RadialGradient(
    center: Alignment(-0.7, -0.8),
    radius: 1.1,
    colors: [Color(0x16E8A020), Color(0x00E8A020)],
  );

  /// Ambient indigo mesh — lower bleed (use in Stack)
  static const RadialGradient meshIndigo = RadialGradient(
    center: Alignment(0.8, 1.0),
    radius: 0.9,
    colors: [Color(0x10594FD4), Color(0x00594FD4)],
  );

  /// Button fill — warm directional amber
  static const LinearGradient amberBtn = LinearGradient(
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
    colors: [Color(0xFFF5C050), Color(0xFFE8A020), Color(0xFFCC8C18)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Button fill — pressed state
  static const LinearGradient amberBtnPressed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8A020), Color(0xFFAA7010)],
  );

  /// Frosted glass card surface
  static const LinearGradient glassSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x18FFFFFF), Color(0x06FFFFFF)],
  );

  /// Subtle amber tint — used on feature badges/chips
  static const LinearGradient amberTint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x22E8A020), Color(0x0AE8A020)],
  );

  // ── Spacing ────────────────────────────────────────────────────────────────

  static const double s2  = 2.0;
  static const double s4  = 4.0;
  static const double s6  = 6.0;
  static const double s8  = 8.0;
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

  // Legacy aliases — existing code continues to compile
  static const double xs  = s4;
  static const double sm  = s8;
  static const double md  = s16;
  static const double lg  = s24;
  static const double xl  = s32;
  static const double xxl = s48;

  // ── Radii ─────────────────────────────────────────────────────────────────

  static const double rXs   = 4.0;
  static const double rSm   = 8.0;
  static const double rMd   = 12.0;
  static const double rLg   = 18.0;
  static const double rXl   = 24.0;
  static const double rFull = 999.0;

  // Legacy aliases
  static const double radiusSm = rSm;
  static const double radiusMd = rMd;
  static const double radiusLg = rLg;
  static const double radiusXl = rXl;

  // ── Animation Timings ──────────────────────────────────────────────────────

  static const Duration tFast   = Duration(milliseconds: 160);
  static const Duration tMid    = Duration(milliseconds: 320);
  static const Duration tSlow   = Duration(milliseconds: 540);
  static const Duration tXSlow  = Duration(milliseconds: 800);

  // ── Animation Curves ──────────────────────────────────────────────────────

  /// Entrance: starts fast, decelerates smoothly to rest
  static const Curve curveEntrance = Curves.easeOutExpo;
  /// Exit: starts slow, accelerates away
  static const Curve curveExit     = Curves.easeInCubic;
  /// Generic smooth — in-out for state changes
  static const Curve curveSmooth   = Curves.easeInOutCubic;
  /// Spring — use for scale/bounce effects
  static const Curve curveSpring   = Curves.elasticOut;

  // ── Typography ─────────────────────────────────────────────────────────────
  //
  // Pairing: Outfit (display) + DM Sans (body)
  // Outfit is geometric-humanist — authoritative but not sterile.
  // DM Sans is highly legible at small sizes on camera labels.
  //

  static TextTheme get textTheme => TextTheme(
    displayLarge: GoogleFonts.outfit(
      fontSize: 38, fontWeight: FontWeight.w700,
      color: textPrimary, letterSpacing: -1.5, height: 1.05,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 30, fontWeight: FontWeight.w700,
      color: textPrimary, letterSpacing: -0.8, height: 1.1,
    ),
    displaySmall: GoogleFonts.outfit(
      fontSize: 24, fontWeight: FontWeight.w600,
      color: textPrimary, letterSpacing: -0.4,
    ),
    headlineLarge: GoogleFonts.outfit(
      fontSize: 22, fontWeight: FontWeight.w600,
      color: textPrimary, letterSpacing: -0.3,
    ),
    headlineMedium: GoogleFonts.outfit(
      fontSize: 18, fontWeight: FontWeight.w600,
      color: textPrimary, letterSpacing: -0.1,
    ),
    headlineSmall: GoogleFonts.outfit(
      fontSize: 15, fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16, fontWeight: FontWeight.w400,
      color: textPrimary, height: 1.6,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14, fontWeight: FontWeight.w400,
      color: textSecondary, height: 1.55,
    ),
    bodySmall: GoogleFonts.dmSans(
      fontSize: 12, fontWeight: FontWeight.w400,
      color: textHint, height: 1.45,
    ),
    labelLarge: GoogleFonts.dmSans(
      fontSize: 14, fontWeight: FontWeight.w600,
      color: textPrimary, letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.dmSans(
      fontSize: 12, fontWeight: FontWeight.w500,
      color: textSecondary, letterSpacing: 0.2,
    ),
    labelSmall: GoogleFonts.dmSans(
      fontSize: 10, fontWeight: FontWeight.w500,
      color: textHint, letterSpacing: 0.5,
    ),
  );

  // ── Theme Data ─────────────────────────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgBase,
    textTheme: textTheme,

    colorScheme: const ColorScheme.dark(
      primary:          amber,
      onPrimary:        textOnAmber,
      secondary:        amberLight,
      onSecondary:      textOnAmber,
      surface:          bgSurface,
      onSurface:        textPrimary,
      surfaceContainer: bgCard,
      outline:          borderSubtle,
      error:            error,
      onError:          textOnAmber,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor:        Colors.transparent,
      elevation:              0,
      scrolledUnderElevation: 0,
      systemOverlayStyle:     SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: textSecondary, size: 20,
      ),
    ),

    inputDecorationTheme: _buildInputDecoration(),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: amber,
        textStyle: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: borderSubtle, thickness: 1, space: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: bgElevated,
      contentTextStyle: GoogleFonts.dmSans(color: textPrimary, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(rMd),
        side: const BorderSide(color: borderSubtle),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
  );

  static InputDecorationTheme _buildInputDecoration() =>
      InputDecorationTheme(
        filled:         true,
        fillColor:      bgCard,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: s16, vertical: s18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: borderSubtle),
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
        hintStyle:          GoogleFonts.dmSans(color: textHint, fontSize: 14),
        labelStyle:         GoogleFonts.dmSans(color: textSecondary, fontSize: 14),
        floatingLabelStyle: GoogleFonts.dmSans(color: amber, fontSize: 12),
        prefixIconColor:    textHint,
        suffixIconColor:    textHint,
        errorStyle:         GoogleFonts.dmSans(color: error, fontSize: 11),
      );

  // Hack to use s18 in static method — just inline the value
  static const double s18 = 18.0;

  // ── Convenience Decoration Builders ───────────────────────────────────────
  //
  // Call these from widget files to stay DRY.
  //

  /// Glass card decoration — frosted surface with subtle border
  static BoxDecoration glassCard({
    double? radius,
    Color? borderColor,
    bool addShadow = true,
  }) =>
      BoxDecoration(
        gradient: glassSurface,
        borderRadius: BorderRadius.circular(radius ?? rLg),
        border: Border.all(
          color: borderColor ?? borderSubtle,
          width: 1,
        ),
        boxShadow: addShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      );

  /// Amber glow container — for icon holders, badges
  static BoxDecoration amberIconBox({double radius = rMd}) =>
      BoxDecoration(
        gradient: amberTint,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderAmber),
        boxShadow: [
          BoxShadow(
            color: amberGlow10,
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      );
}