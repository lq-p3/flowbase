import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../navigation.dart';
import '../widgets/controls.dart';
import '../widgets/layout.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    void settings() => push(context, const SettingsScreen());
    final themeLabel = switch (app.themeMode) { ThemeMode.dark => t['dark'], ThemeMode.system => t['system'], _ => t['light'] };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DetailHeader(
              title: t['profile'],
              trailing: FbIconButton(icon: Icons.settings_outlined, label: t['settings'], onTap: settings),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 28),
                children: [
                  FbCard(
                    radius: 20,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(children: [
                      const ExcludeSemantics(child: Avatar(size: 76, filled: true)),
                      const SizedBox(height: 12),
                      Text(app.userName.isEmpty ? t['user'] : app.userName, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: c.text)),
                      const SizedBox(height: 4),
                      Text(app.email, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 14, color: c.text2)),
                      const SizedBox(height: 16),
                      SecondaryButton(label: t['editProfile'], icon: Icons.edit_outlined, height: 40, expand: false, onPressed: settings),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  StatStrip(items: [
                    ('${app.completedCount}', t['completedTasks']),
                    ('${app.activeProjects.length}', t['activeProjectsStat']),
                    ('${app.spaces.length}', t['spacesStat']),
                  ]),
                  const SizedBox(height: 16),
                  GroupCard(children: [
                    ListRow(icon: Icons.person_outline_rounded, iconTile: true, label: t['account'], onTap: settings),
                    ListRow(
                      icon: app.themeMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      iconTile: true,
                      label: t['appearance'],
                      value: themeLabel,
                      onTap: settings,
                    ),
                    ListRow(icon: Icons.language_rounded, iconTile: true, label: t['language'], value: app.isAr ? 'العربية' : 'English', onTap: settings),
                    ListRow(
                      icon: Icons.notifications_none_rounded,
                      iconTile: true,
                      label: t['notifications'],
                      value: app.notifTasks || app.notifDue ? t['on'] : t['off'],
                      onTap: settings,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
