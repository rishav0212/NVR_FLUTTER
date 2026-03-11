import 'package:flutter/services.dart';

// ═════════════════════════════════════════════════════════════════════════════
// APP HAPTICS — centralized haptic feedback
// ═════════════════════════════════════════════════════════════════════════════
//
// All haptic calls go through here.
// Benefits:
//   • Easy to disable globally (e.g. user preference)
//   • Easy to test (mock one class)
//   • Consistent semantics across features
//
// Usage:
//   AppHaptics.light()     — tap acknowledge, icon press
//   AppHaptics.medium()    — primary button press
//   AppHaptics.error()     — validation fail, wrong password
//   AppHaptics.success()   — login/register success
//   AppHaptics.selection() — toggle, radio, checkbox change
//
class AppHaptics {
  AppHaptics._();

  /// Subtle confirmation — minor interactions
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Standard confirmation — button press, form submit
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Strong emphasis — destructive action
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Login, register, profile saved — positive outcome
  static Future<void> success() => HapticFeedback.mediumImpact();

  /// Wrong credentials, validation failure — draws attention to error
  static Future<void> error() => HapticFeedback.heavyImpact();

  /// Toggle switch, theme change, radio selection
  static Future<void> selection() => HapticFeedback.selectionClick();
}
