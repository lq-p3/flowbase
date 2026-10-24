import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/reminders.dart';
import 'core/theme.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_state.dart';
import 'widgets/overlays.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connects to Supabase and restores the saved login (if any) from the phone.
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  final reminders = Reminders();
  try {
    await reminders.init();
  } catch (_) {
    // Notifications unavailable: the app still works without them.
  }
  final state = AppState(db: Supabase.instance.client, reminders: reminders);
  await state.loadPrefs();
  if (state.signedIn) state.load();
  runApp(FlowBaseApp(state: state, startInApp: state.signedIn));
}

class FlowBaseApp extends StatelessWidget {
  const FlowBaseApp({super.key, required this.state, this.startInApp = false});
  final AppState state;

  /// True when the phone already has a saved login at launch.
  final bool startInApp;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'FlowBase',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: messengerKey,
          theme: buildTheme(Brightness.light, state.isAr),
          darkTheme: buildTheme(Brightness.dark, state.isAr),
          themeMode: state.themeMode,
          locale: state.locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => DevicePreview(child: child ?? const SizedBox()),
          // Already signed in on this phone → straight to the app.
          home: startInApp ? const MainShell() : const OnboardingScreen(),
        ),
      ),
    );
  }
}

/// On wide screens (desktop / web during development) the app is shown
/// centered at phone size (393 × 852). On a real phone it fills the screen.
class DevicePreview extends StatelessWidget {
  const DevicePreview({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width < 600) return child;
    const w = 393.0;
    final h = mq.size.height - 48 < 852 ? mq.size.height - 48 : 852.0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: dark ? const Color(0xFF07080F) : const Color(0xFFE9EBF3),
      child: Center(
        child: Container(
          width: w,
          height: h,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: dark ? const Color(0xFF272A3D) : const Color(0xFFD5D8E4), width: 1),
            boxShadow: const [BoxShadow(color: Color(0x1F17182B), blurRadius: 40, offset: Offset(0, 16))],
          ),
          child: MediaQuery(
            data: mq.copyWith(size: Size(w, h), padding: const EdgeInsets.only(top: 12, bottom: 12), viewPadding: const EdgeInsets.only(top: 12, bottom: 12)),
            child: child,
          ),
        ),
      ),
    );
  }
}
