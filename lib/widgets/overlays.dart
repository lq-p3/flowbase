import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../data/models.dart';
import '../navigation.dart';
import '../screens/project_form_screen.dart';
import '../screens/space_form_screen.dart';
import '../screens/task_form_screen.dart';
import '../state/app_state.dart' show kToday;
import 'controls.dart';
import 'fb_icons.dart';
import 'layout.dart';

/// Root messenger so toasts survive route pops.
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Small, non-intrusive toast.
void showToast(String message, {IconData icon = Icons.check_circle_outline_rounded}) {
  final m = messengerKey.currentState;
  final ctx = messengerKey.currentContext;
  if (m == null || ctx == null) return;
  final c = FbColors.of(ctx);
  m
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 2200),
        backgroundColor: c.toastBg,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(icon, size: 19, color: c.toastIcon),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
}

/// Destructive confirmation dialog. Resolves to true when the user confirms.
Future<bool> showConfirm(BuildContext context, {required String title, required String message}) async {
  final c = context.fb;
  final t = context.s;
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: c.scrim,
    builder: (ctx) => Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.modal)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(icon: Icons.delete_outline_rounded, bg: c.dangerBg, fg: c.dangerText, size: 52),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, height: 1.5, color: c.text2)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: SecondaryButton(label: t['cancel'], height: 48, onPressed: () => Navigator.pop(ctx, false))),
                  const SizedBox(width: 10),
                  Expanded(child: PrimaryButton(label: t['delete'], danger: true, height: 48, onPressed: () => Navigator.pop(ctx, true))),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}

/// Opens a bottom sheet with FlowBase styling.
Future<T?> showFbSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.fb.surface,
    barrierColor: context.fb.scrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.sheet))),
    builder: builder,
  );
}

class SheetAction {
  const SheetAction(this.icon, this.label, this.onTap, {this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
}

/// "More" menu for detail screens.
void showActionsSheet(BuildContext context, List<SheetAction> actions) {
  showFbSheet<void>(context, (ctx) {
    final c = ctx.fb;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.page, 0, Sp.page, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DragHandle(),
            for (final a in actions)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pop(ctx);
                  a.onTap();
                },
                child: SizedBox(
                  height: 54,
                  child: Row(
                    children: [
                      Icon(a.icon, size: 21, color: a.danger ? c.dangerText : c.text),
                      const SizedBox(width: 14),
                      Text(a.label, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: a.danger ? c.dangerText : c.text)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SecondaryButton(label: ctx.s['cancel'], height: 50, onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  });
}

/// The center "+" button menu: New Task / New Project / New Space.
void showCreateSheet(BuildContext context) {
  showFbSheet<void>(context, (ctx) {
    final c = ctx.fb;
    final t = ctx.s;
    Widget option(IconData icon, Color bg, Color fg, String title, String sub, Widget page) => InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(ctx);
            push(context, page);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                IconTile(icon: icon, bg: bg, fg: fg, size: 44, iconSize: 21),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: c.text)),
                      const SizedBox(height: 2),
                      Text(sub, style: TextStyle(fontSize: 13, color: c.text2)),
                    ],
                  ),
                ),
                DirIcon(Icons.chevron_right_rounded, size: 20, color: c.muted),
              ],
            ),
          ),
        );
    final noSpaces = ctx.appRead.spaces.isEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.page, 0, Sp.page, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragHandle(),
            Row(
              children: [
                Expanded(child: Text(t['create'], style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: c.text))),
                FbIconButton(icon: Icons.close_rounded, label: t['close'], onTap: () => Navigator.pop(ctx), foreground: c.text2),
              ],
            ),
            const SizedBox(height: 4),
            option(Icons.checklist_rounded, c.primaryLight, c.primaryText, t['newTask'], t['newTaskSub'],
                noSpaces ? const SpaceFormScreen() : const TaskFormScreen()),
            option(Icons.folder_outlined, c.successBg, c.successText, t['newProject'], t['newProjectSub'],
                noSpaces ? const SpaceFormScreen() : const ProjectFormScreen()),
            option(Icons.grid_view_rounded, c.warningBg, c.warningText, t['newSpace'], t['newSpaceSub'], const SpaceFormScreen()),
          ],
        ),
      ),
    );
  });
}

/// Filters bottom sheet for the Tasks screen.
void showFiltersSheet(BuildContext context) {
  showFbSheet<void>(context, (_) => const _FiltersSheet());
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet();
  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String status;
  late Set<Priority> prios;
  late Set<String> spaces;
  String? projectId;
  String? due;
  DateTime? customDate;

  @override
  void initState() {
    super.initState();
    final f = context.appRead.filters;
    status = f.status;
    prios = {...f.priorities};
    spaces = {...f.spaces};
    projectId = f.projectId;
    due = f.due;
    customDate = f.customDate;
  }

  TaskFilters get _draft => TaskFilters(
        status: status,
        priorities: prios,
        spaces: spaces,
        projectId: projectId,
        due: due,
        customDate: customDate,
      );

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;
    final ar = app.isAr;
    final draft = _draft;
    final count = app.tasks.where((x) => draft.matches(x, kToday)).length;
    final projects = app.projects.where((p) => spaces.isEmpty || spaces.contains(p.spaceId)).toList();

    Widget section(String label, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(label, style: FbText.label(c.text)), const SizedBox(height: 10), child],
          ),
        );
    Widget wrap(List<Widget> chips) => Wrap(spacing: 8, runSpacing: 8, children: chips);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.page),
            child: Column(children: [
              const DragHandle(),
              Row(children: [
                Expanded(child: Text(t['filters'], style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: c.text))),
                FbIconButton(icon: Icons.close_rounded, label: t['close'], onTap: () => Navigator.pop(context), foreground: c.text2),
              ]),
            ]),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 0),
              children: [
                section(
                  t['fStatus'],
                  wrap([
                    for (final s in const ['all', 'active', 'completed'])
                      FbChip(
                        label: t[s == 'all' ? 'fAll' : s == 'active' ? 'fActive' : 'fCompleted'],
                        selected: status == s,
                        onTap: () => setState(() => status = s),
                      ),
                  ]),
                ),
                section(
                  t['fPriority'],
                  wrap([
                    for (final p in Priority.values)
                      FbChip(
                        label: t[p.name],
                        selected: prios.contains(p),
                        onTap: () => setState(() => prios.contains(p) ? prios.remove(p) : prios.add(p)),
                      ),
                  ]),
                ),
                section(
                  t['fSpace'],
                  wrap([
                    for (final s in app.spaces)
                      FbChip(
                        label: s.name.of(ar),
                        icon: FbIcons.of(s.icon),
                        showCheck: false,
                        selected: spaces.contains(s.id),
                        onTap: () => setState(() {
                          spaces.contains(s.id) ? spaces.remove(s.id) : spaces.add(s.id);
                          final p = app.project(projectId);
                          if (p != null && spaces.isNotEmpty && !spaces.contains(p.spaceId)) projectId = null;
                        }),
                      ),
                  ]),
                ),
                section(
                  t['fProject'],
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        FbChip(label: t['anyProject'], selected: projectId == null, onTap: () => setState(() => projectId = null)),
                        for (final p in projects) ...[
                          const SizedBox(width: 8),
                          FbChip(
                            label: p.name.of(ar),
                            selected: projectId == p.id,
                            onTap: () => setState(() => projectId = projectId == p.id ? null : p.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                section(
                  t['fDue'],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      wrap([
                        for (final d in const ['today', 'tomorrow', 'week', 'custom'])
                          FbChip(
                            label: t[{'today': 'dToday', 'tomorrow': 'dTomorrow', 'week': 'dWeek', 'custom': 'dCustom'}[d]!],
                            selected: due == d,
                            onTap: () async {
                              if (d == 'custom') {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: customDate ?? kToday,
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2028),
                                  helpText: t['pickDate'],
                                );
                                if (picked == null || !mounted) return;
                                setState(() {
                                  due = 'custom';
                                  customDate = DateTime.utc(picked.year, picked.month, picked.day);
                                });
                              } else {
                                setState(() => due = due == d ? null : d);
                              }
                            },
                          ),
                      ]),
                      if (due == 'custom' && customDate != null) ...[
                        const SizedBox(height: 8),
                        Text(f.full(customDate!), style: TextStyle(fontSize: 13, color: c.text2)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          BottomActionBar(
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: t['reset'],
                    onPressed: () => setState(() {
                      status = 'all';
                      prios = {};
                      spaces = {};
                      projectId = null;
                      due = null;
                      customDate = null;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: f.showN(count),
                    onPressed: () {
                      context.appRead.setFilters(_draft);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

