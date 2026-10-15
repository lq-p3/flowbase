import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../data/models.dart';
import '../navigation.dart';
import '../widgets/cards.dart';
import '../widgets/controls.dart';
import '../widgets/fb_icons.dart';
import '../widgets/layout.dart';
import '../widgets/overlays.dart';
import 'project_form_screen.dart';

class SpaceDetailScreen extends StatelessWidget {
  const SpaceDetailScreen({super.key, required this.spaceId});
  final String spaceId;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final space = app.space(spaceId);
    if (space == null) return const Scaffold(body: SizedBox());
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;
    final ar = app.isAr;
    final tone = toneColors(c, space.tone);
    final projects = app.projectsIn(space.id);
    final tasks = app.tasksIn(space.id);
    final active = tasks.where((x) => !x.isDone).toList()..sort((a, b) => a.sortKey.compareTo(b.sortKey));

    void addProject() => push(context, ProjectFormScreen(spaceId: space.id));

    Future<void> delete() async {
      final ok = await showConfirm(context, title: t['dSpaceT'], message: t['dSpaceM']);
      if (!ok || !context.mounted) return;
      final a = context.appRead;
      Navigator.pop(context);
      a.deleteSpace(space.id);
      showToast(t['spaceDeleted'], icon: Icons.delete_outline_rounded);
    }

    void viewAll() {
      final a = context.appRead;
      a.setFilters(TaskFilters(spaces: {space.id}));
      a.setTab(1);
      Navigator.of(context).popUntil((r) => r.isFirst);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DetailHeader(
              title: space.name.of(ar),
              trailing: FbIconButton(
                icon: Icons.more_horiz_rounded,
                label: t['more'],
                onTap: () => showActionsSheet(context, [
                  SheetAction(Icons.add_rounded, t['addProjectA'], addProject),
                  SheetAction(Icons.delete_outline_rounded, t['deleteSpaceA'], delete, danger: true),
                ]),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 28),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconTile(icon: FbIcons.of(space.icon), bg: tone.bg, fg: tone.fg, size: 56, iconSize: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(space.name.of(ar), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: c.text)),
                            if (!space.description.isEmpty) ...[
                              const SizedBox(height: 4),
                              Text(space.description.of(ar), style: TextStyle(fontSize: 14, height: 1.45, color: c.text2)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  StatStrip(items: [
                    ('${projects.length}', t['projectsStat']),
                    ('${active.length}', t['activeTasks']),
                    ('${tasks.length - active.length}', t['completed']),
                  ]),
                  const SizedBox(height: 14),
                  SectionHeader(title: t['projects']),
                  if (projects.isEmpty)
                    EmptyState(
                      icon: Icons.folder_outlined,
                      title: t['noProjects'],
                      message: t['noProjectsSub'],
                      actionLabel: t['createProject'],
                      onAction: addProject,
                    )
                  else ...[
                    for (final p in projects) Padding(padding: const EdgeInsets.only(bottom: 10), child: ProjectRow(project: p)),
                    SecondaryButton(label: t['addProject'], icon: Icons.add_rounded, height: 50, onPressed: addProject),
                  ],
                  const SizedBox(height: 14),
                  SectionHeader(title: t['tasks'], action: active.isNotEmpty ? t['viewAllTasks'] : null, onAction: viewAll),
                  if (active.isEmpty)
                    Text(t['noActiveTasks'], style: TextStyle(fontSize: 14, color: c.text2))
                  else
                    for (final task in active.take(4))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TaskCard(key: ValueKey(task.id), task: task, mode: WhenMode.date),
                      ),
                  if (active.length > 4)
                    Text(f.nActive(active.length), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.text2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
