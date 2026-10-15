import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'format.dart';
import 'strings.dart';
import 'tokens.dart';

/// Short-hands used everywhere:
///   context.fb   → colors       context.s['key'] → text
///   context.app  → state (listens)   context.appRead → state (no rebuild)
///   context.fmt  → dates & plurals
extension FbContext on BuildContext {
  FbColors get fb => FbColors.of(this);
  AppState get app => AppScope.of(this);
  AppState get appRead => AppScope.read(this);
  bool get isAr => AppScope.read(this).isAr;
  Strings get s => Strings(AppScope.of(this).isAr);
  Fmt get fmt => Fmt(AppScope.of(this).isAr);
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
