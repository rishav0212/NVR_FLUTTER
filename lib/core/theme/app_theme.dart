import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// NVR Platform Design System
///
/// Design direction: "Dark Precision" — inspired by high-end security
/// dashboards and professional monitoring tools. Think Bloomberg Terminal
/// meets modern fintech. Deep dark backgrounds with sharp amber/gold accents.
///
/// The palette avoids the typical "blue gradient on white" CCTV app look.
/// Instead: near-black surfaces, warm amber as the primary accent (evokes
/// security lighting, warmth, visibility), and cool slate for neutrals.
///
/// Now fully supports both Light and Dark modes with smooth page transitions,
/// automatically adapting to the user's system preferences.
///
/// Typography: Syne for display (geometric, authoritative) paired with
/// DM Sans for body (clean, legible at small sizes on camera labels).
///
/// All colors, spacings, and text styles are defined here.
/// Never hardcode colors or text styles in widget files.
class AppTheme {
  // ─── Color Palette ──────────────────────────────────────────────────────────

  /// Deep background — darker than typical "dark mode" for high contrast
  static const Color backgroundDark = Color(0xFF0A0A0F);
  static const Color surfaceDark = Color(0xFF12121A);
  static const Color surfaceElevated = Color(0xFF1A1A26);
  static const Color surfaceBorder = Color(0xFF252535);

  /// Amber — primary accent. Security/warmth. Unique in the CCTV space.
  static const Color amber = Color(0xFFE8A020);
  static const Color amberLight = Color(0xFFF5B940);
  static const Color amberDim = Color(0xFF8A5F12);
  static const Color amberGlow = Color(0x26E8A020); // 15% opacity

  /// Status colors
  static const Color onlineGreen = Color(0xFF22C55E);
  static const Color offlineRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF97316);

  /// Text hierarchy
  static const Color textPrimary = Color(0xFFF0F0F8);
  static const Color textSecondary = Color(0xFF8888A8);
  static const Color textMuted = Color(0xFF44445A);
  static const Color textOnAmber = Color(0xFF0A0A0F);

  // ─── Spacing ─────────────────────────────────────────────────────────────────

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ─── Border Radius ───────────────────────────────────────────────────────────

  static const double radiusSm = 6.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;

  // ─── Typography Generator ────────────────────────────────────────────────────

  /// Generates the text theme dynamically based on mode (Light/Dark) colors
  static TextTheme _buildTextTheme(
    Color primary,
    Color secondary,
    Color muted,
  ) => TextTheme(
    // Display — app name, large headings
    displayLarge: GoogleFonts.syne(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: primary,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.syne(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: primary,
      letterSpacing: -0.3,
    ),
    // Headings
    headlineLarge: GoogleFonts.syne(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    headlineMedium: GoogleFonts.syne(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    headlineSmall: GoogleFonts.syne(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    // Body
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: secondary,
    ),
    bodySmall: GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: muted,
    ),
    // Labels
    labelLarge: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: 0.2,
    ),
    labelMedium: GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: secondary,
      letterSpacing: 0.3,
    ),
    labelSmall: GoogleFonts.dmSans(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: muted,
      letterSpacing: 0.5,
    ),
  );

  // ─── Global Transitions ───────────────────────────────────────────────────

  /// Applies a smooth, premium fade-and-scale transition across the app
  /// instead of the harsh default Android slide.
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );

  // ─── Dark Theme ──────────────────────────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    textTheme: _buildTextTheme(textPrimary, textSecondary, textMuted),
    pageTransitionsTheme: _pageTransitions,

    colorScheme: const ColorScheme.dark(
      primary: amber,
      onPrimary: textOnAmber,
      secondary: amberLight,
      onSecondary: textOnAmber,
      surface: surfaceDark,
      onSurface: textPrimary,
      surfaceContainer: surfaceElevated,
      outline: surfaceBorder,
      error: offlineRed,
    ),

    appBarTheme: _buildAppBarTheme(backgroundDark, textPrimary),
    inputDecorationTheme: _buildInputTheme(
      surfaceElevated,
      surfaceBorder,
      textPrimary,
    ),
    elevatedButtonTheme: _buildElevatedBtn(amber, textOnAmber),
    outlinedButtonTheme: _buildOutlinedBtn(surfaceBorder, textPrimary),
    textButtonTheme: _buildTextBtn(amber),

    // Dividers
    dividerTheme: const DividerThemeData(
      color: surfaceBorder,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: _buildSnackBar(surfaceElevated, surfaceBorder, textPrimary),
  );

  // ─── Light Theme ──────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    const bg = Color(0xFFF8F9FA);
    const surface = Color(0xFFFFFFFF);
    const surfaceElevated = Color(0xFFF1F3F5);
    const border = Color(0xFFDEE2E6);
    const textPrimaryLight = Color(0xFF212529);
    const textSecondaryLight = Color(0xFF495057);
    const textMutedLight = Color(0xFF868E96);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      textTheme: _buildTextTheme(
        textPrimaryLight,
        textSecondaryLight,
        textMutedLight,
      ),
      pageTransitionsTheme: _pageTransitions,

      colorScheme: const ColorScheme.light(
        primary: amber,
        onPrimary: Colors.white,
        secondary: amberLight,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimaryLight,
        surfaceContainer: surfaceElevated,
        outline: border,
        error: offlineRed,
      ),

      appBarTheme: _buildAppBarTheme(bg, textPrimaryLight),
      inputDecorationTheme: _buildInputTheme(
        surfaceElevated,
        border,
        textPrimaryLight,
      ),
      elevatedButtonTheme: _buildElevatedBtn(amber, Colors.white),
      outlinedButtonTheme: _buildOutlinedBtn(border, textPrimaryLight),
      textButtonTheme: _buildTextBtn(amber),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: _buildSnackBar(surface, border, textPrimaryLight),
    );
  }

  // ─── Reusable Component Themes ────────────────────────────────────────────

  // App bar — flush with background
  static AppBarTheme _buildAppBarTheme(Color bg, Color text) => AppBarTheme(
    backgroundColor: bg,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: GoogleFonts.syne(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: text,
    ),
    iconTheme: IconThemeData(color: text),
  );

  // Input fields — subtle border, amber focus ring
  static InputDecorationTheme _buildInputTheme(
    Color fill,
    Color border,
    Color text,
  ) => InputDecorationTheme(
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: md, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: const BorderSide(color: amber, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: const BorderSide(color: offlineRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: const BorderSide(color: offlineRed, width: 1.5),
    ),
    hintStyle: GoogleFonts.dmSans(color: border.withOpacity(0.8), fontSize: 14),
    labelStyle: GoogleFonts.dmSans(color: text.withOpacity(0.7), fontSize: 14),
    floatingLabelStyle: GoogleFonts.dmSans(color: amber, fontSize: 12),
    prefixIconColor: text.withOpacity(0.5),
    suffixIconColor: text.withOpacity(0.5),
  );

  // Primary buttons — solid amber
  static ElevatedButtonThemeData _buildElevatedBtn(Color bg, Color fg) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          elevation: 0,
        ),
      );

  // Outlined buttons — border only
  static OutlinedButtonThemeData _buildOutlinedBtn(Color border, Color fg) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  // Text buttons — amber label, no background
  static TextButtonThemeData _buildTextBtn(Color fg) => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: fg,
      textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  );

  // Snackbars
  static SnackBarThemeData _buildSnackBar(Color bg, Color border, Color text) =>
      SnackBarThemeData(
        backgroundColor: bg,
        contentTextStyle: GoogleFonts.dmSans(color: text, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: border),
        ),
        behavior: SnackBarBehavior.floating,
      );
}
