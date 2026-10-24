import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../navigation.dart';
import '../widgets/controls.dart';
import '../widgets/layout.dart';
import '../widgets/overlays.dart';
import 'onboarding_screen.dart';
import 'states_preview_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    void soon() => showToast(t['comingSoon'], icon: Icons.info_outline_rounded);
    void toStart() => Navigator.of(context).pushAndRemoveUntil(fbRoute(const OnboardingScreen()), (_) => false);

    Future<void> signOut() async {
      await context.appRead.signOut();
      toStart();
    }

    Future<void> deleteAccount() async {
      final ok = await showConfirm(context, title: t['dAccT'], message: t['dAccM']);
      if (!ok || !context.mounted) return;
      await context.appRead.deleteAllData();
      toStart();
    }

    void about() => showDialog<void>(
          context: context,
          barrierColor: c.scrim,
          builder: (ctx) => Dialog(
            backgroundColor: c.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.modal)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const BrandMark(size: 40),
                const SizedBox(height: 14),
                Text(t['tagline'], textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
                const SizedBox(height: 6),
                Text(t['version'], style: TextStyle(fontSize: 13, color: c.text2)),
                const SizedBox(height: 18),
                SecondaryButton(label: t['ok'], height: 46, onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
          ),
        );

    Widget themeOption(ThemeMode m, IconData icon, String label) {
      final sel = app.themeMode == m;
      return Expanded(
        child: Semantics(
          button: true,
          selected: sel,
          child: GestureDetector(
            onTap: () => context.appRead.setTheme(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 66,
              decoration: BoxDecoration(
                color: sel ? c.primaryLight : c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? c.primary : c.border, width: 1.5),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 21, color: sel ? c.primaryText : c.text),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? c.primaryText : c.text)),
              ]),
            ),
          ),
        ),
      );
    }

    Widget langOption(String code, String label) {
      final sel = app.lang == code;
      return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: sel,
        child: ListRow(
          label: label,
          onTap: () => context.appRead.setLang(code),
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: sel ? c.primary : c.borderStrong, width: 2)),
            child: sel ? Container(width: 10, height: 10, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)) : null,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DetailHeader(title: t['settings']),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 28),
                children: [
                  CapsLabel(t['account']),
                  GroupCard(children: [
                    ListRow(icon: Icons.person_outline_rounded, label: t['profileL'], value: app.userName.isEmpty ? t['user'] : app.userName, onTap: () => Navigator.maybePop(context)),
                    ListRow(icon: Icons.mail_outline_rounded, label: t['emailL'], value: app.email, onTap: soon),
                    ListRow(icon: Icons.lock_outline_rounded, label: t['passwordL'], onTap: soon),
                  ]),
                  const SizedBox(height: 22),
                  CapsLabel(t['appearance']),
                  FbCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t['theme'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.text)),
                      const SizedBox(height: 12),
                      Row(children: [
                        themeOption(ThemeMode.light, Icons.light_mode_outlined, t['light']),
                        const SizedBox(width: 8),
                        themeOption(ThemeMode.dark, Icons.dark_mode_outlined, t['dark']),
                        const SizedBox(width: 8),
                        themeOption(ThemeMode.system, Icons.brightness_auto_outlined, t['system']),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  CapsLabel(t['language']),
                  GroupCard(children: [langOption('en', 'English'), langOption('ar', 'العربية')]),
                  const SizedBox(height: 22),
                  CapsLabel(t['notifications']),
                  GroupCard(children: [
                    ListRow(
                      icon: Icons.notifications_none_rounded,
                      label: t['taskReminders'],
                      onTap: () => context.appRead.setNotif(tasksOn: !app.notifTasks),
                      trailing: FbSwitch(value: app.notifTasks, onChanged: (v) => context.appRead.setNotif(tasksOn: v)),
                    ),
                    ListRow(
                      icon: Icons.event_outlined,
                      label: t['dueReminders'],
                      onTap: () => context.appRead.setNotif(dueOn: !app.notifDue),
                      trailing: FbSwitch(value: app.notifDue, onChanged: (v) => context.appRead.setNotif(dueOn: v)),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  CapsLabel(t['other']),
                  GroupCard(children: [
                    ListRow(icon: Icons.info_outline_rounded, label: t['about'], value: t['version'], onTap: about),
                    ListRow(icon: Icons.shield_outlined, label: t['privacy'], onTap: soon),
                    ListRow(icon: Icons.help_outline_rounded, label: t['help'], onTap: soon),
                    if (kDebugMode)
                      ListRow(
                        icon: Icons.layers_outlined,
                        label: t['statesPreview'],
                        onTap: () => push(context, const StatesPreviewScreen()),
                      ),
                  ]),
                  const SizedBox(height: 22),
                  SecondaryButton(label: t['signOut'], icon: Icons.logout_rounded, onPressed: signOut),
                  const SizedBox(height: 22),
                  CapsLabel(t['dangerZone'], color: c.dangerText),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(Rad.card),
                      border: Border.all(color: c.dangerBorder),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(t['deleteAccount'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
                      const SizedBox(height: 3),
                      Text(t['deleteAccountSub'], style: TextStyle(fontSize: 13.5, height: 1.45, color: c.text2)),
                      const SizedBox(height: 12),
                      SecondaryButton(label: t['deleteAccount'], icon: Icons.delete_outline_rounded, danger: true, height: 46, onPressed: deleteAccount),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text('FlowBase · ${t['tagline']}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: c.text2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
