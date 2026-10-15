import 'package:flutter/material.dart';

import 'tokens.dart';

final Map<String, ThemeData> _cache = {};

/// Builds the FlowBase theme. Inter for English, IBM Plex Sans Arabic for Arabic
/// (both bundled in assets/fonts, so they work offline with real weights).
ThemeData buildTheme(Brightness brightness, bool arabic) {
  final key = '${brightness.name}-$arabic';
  return _cache[key] ??= _build(brightness, arabic);
}

ThemeData _build(Brightness brightness, bool arabic) {
  final c = brightness == Brightness.dark ? FbColors.dark : FbColors.light;
  final family = arabic ? 'IBMPlexSansArabic' : 'Inter';
  final fallback = arabic ? const ['Inter'] : const ['IBMPlexSansArabic'];

  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    fontFamily: family,
    fontFamilyFallback: fallback,
    colorScheme: ColorScheme.fromSeed(seedColor: c.primary, brightness: brightness).copyWith(
      primary: c.primary,
      onPrimary: Colors.white,
      surface: c.surface,
      onSurface: c.text,
      error: c.danger,
      outline: c.border,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    dividerColor: c.border,
    splashFactory: InkRipple.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: c.primary.withAlpha(20),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.primary,
      selectionColor: c.primary.withAlpha(60),
      selectionHandleColor: c.primary,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBackgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.sheet))),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, elevation: 0),
    iconTheme: IconThemeData(color: c.text, size: 22),
  );
}
