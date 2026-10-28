import 'package:flutter/material.dart';

/// FlowBase color tokens. One palette for light, one for dark.
/// Every widget reads colors from here — never hard-code a hex in a screen.
class FbColors {
  const FbColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.text2,
    required this.muted,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primaryText,
    required this.success,
    required this.successBg,
    required this.successText,
    required this.warning,
    required this.warningBg,
    required this.warningText,
    required this.danger,
    required this.dangerSolid,
    required this.dangerBg,
    required this.dangerText,
    required this.dangerBorder,
    required this.neutralBg,
    required this.neutralText,
    required this.skeleton,
    required this.scrim,
    required this.toastBg,
    required this.toastIcon,
    required this.navBg,
  });

  final Color bg, surface, surface2, border, borderStrong, text, text2, muted;
  final Color primary, primaryDark, primaryLight, primaryText;
  final Color success, successBg, successText;
  final Color warning, warningBg, warningText;
  final Color danger, dangerSolid, dangerBg, dangerText, dangerBorder;
  final Color neutralBg, neutralText, skeleton, scrim, toastBg, toastIcon, navBg;

  static const light = FbColors(
    bg: Color(0xFFF7F7F5),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF1F1EF),
    border: Color(0xFFECECEF),
    borderStrong: Color(0xFFD6D7DD),
    text: Color(0xFF15161F),
    text2: Color(0xFF61646F),
    muted: Color(0xFF8A8D98),
    primary: Color(0xFF4F46E5),
    primaryDark: Color(0xFF4338CA),
    primaryLight: Color(0xFFEEEEFD),
    primaryText: Color(0xFF4338CA),
    success: Color(0xFF22A66F),
    successBg: Color(0xFFE6F6EE),
    successText: Color(0xFF137A4D),
    warning: Color(0xFFF59E0B),
    warningBg: Color(0xFFFEF4E2),
    warningText: Color(0xFF9A5B06),
    danger: Color(0xFFEF5350),
    dangerSolid: Color(0xFFD93936),
    dangerBg: Color(0xFFFDECEC),
    dangerText: Color(0xFFC62F2C),
    dangerBorder: Color(0xFFF8CFCE),
    neutralBg: Color(0xFFF1F1F3),
    neutralText: Color(0xFF555A6E),
    skeleton: Color(0xFFEDEDEF),
    scrim: Color(0x6115161F),
    toastBg: Color(0xFF15161F),
    toastIcon: Color(0xFF4ADE9B),
    navBg: Color(0xF5FFFFFF),
  );

  static const dark = FbColors(
    bg: Color(0xFF0E0F14),
    surface: Color(0xFF181920),
    surface2: Color(0xFF202129),
    border: Color(0xFF25262F),
    borderStrong: Color(0xFF34353F),
    text: Color(0xFFECEDF3),
    text2: Color(0xFF9EA1AE),
    muted: Color(0xFF6F7280),
    primary: Color(0xFF6366F1),
    primaryDark: Color(0xFF4F46E5),
    primaryLight: Color(0x296366F1),
    primaryText: Color(0xFFA5B4FC),
    success: Color(0xFF34C486),
    successBg: Color(0x2434C486),
    successText: Color(0xFF5DD8A3),
    warning: Color(0xFFF5B03B),
    warningBg: Color(0x21F5B03B),
    warningText: Color(0xFFF6C063),
    danger: Color(0xFFF26664),
    dangerSolid: Color(0xFFD93936),
    dangerBg: Color(0x24F26664),
    dangerText: Color(0xFFFF8E8C),
    dangerBorder: Color(0x52F26664),
    neutralBg: Color(0x12FFFFFF),
    neutralText: Color(0xFFB7BACB),
    skeleton: Color(0xFF22232B),
    scrim: Color(0x99000000),
    toastBg: Color(0xFF2A2B35),
    toastIcon: Color(0xFF5DD8A3),
    navBg: Color(0xF5181920),
  );

  static FbColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Spacing scale: 4 · 8 · 12 · 16 · 20 · 24 · 32
class Sp {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 20, xxl = 24, xxxl = 32;
  static const double page = 20;
}

/// Corner radii.
class Rad {
  static const double card = 16, button = 14, input = 14, chip = 11, modal = 20, sheet = 24;
}

/// Subtle tints used for Space / Project icons. Only palette colors.
enum Tone { indigo, green, amber, rose, slate }

class ToneColors {
  const ToneColors(this.bg, this.fg, this.solid);
  final Color bg, fg, solid;
}

ToneColors toneColors(FbColors c, Tone t) {
  switch (t) {
    case Tone.indigo:
      return ToneColors(c.primaryLight, c.primaryText, const Color(0xFF4F46E5));
    case Tone.green:
      return ToneColors(c.successBg, c.successText, const Color(0xFF22A66F));
    case Tone.amber:
      return ToneColors(c.warningBg, c.warningText, const Color(0xFFE08F07));
    case Tone.rose:
      return ToneColors(c.dangerBg, c.dangerText, const Color(0xFFEF5350));
    case Tone.slate:
      return ToneColors(c.neutralBg, c.neutralText, const Color(0xFF6F7385));
  }
}

/// Typography scale (font family comes from the theme: Inter / IBM Plex Sans Arabic).
class FbText {
  static TextStyle pageTitle(Color c) =>
      TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2, color: c);
  static TextStyle greeting(Color c) =>
      TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.2, color: c);
  static TextStyle section(Color c) =>
      TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: c);
  static TextStyle headerTitle(Color c) =>
      TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c);
  static TextStyle cardTitle(Color c) =>
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.35, color: c);
  static TextStyle body(Color c) => TextStyle(fontSize: 15, height: 1.5, color: c);
  static TextStyle label(Color c) => TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c);
  static TextStyle meta(Color c) => TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: c);
  static TextStyle caps(Color c) =>
      TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: c);
  static TextStyle button(Color c) => TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c);
}
