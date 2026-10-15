import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../navigation.dart';
import '../widgets/cards.dart';
import '../widgets/controls.dart';
import '../widgets/fb_icons.dart';
import '../widgets/layout.dart';
import '../widgets/overlays.dart';
import 'task_form_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});
  final String projectId;
  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  int _tab = 0; // All · Active · Completed

  Future<void> _delete() async {
    final t = context.s;
    final ok = await showConfirm(context, title: t['dProjT'], message: t['dProjM']);
    if (!ok || !mounted) return;
    final app = context.appRead;
    Navigator.pop(context);
    app.deleteProject(widget.projectId);
    showToast(t['projectDeleted'], icon: Icons.delete_outline_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final project = app.project(widget.projectId);
    if (project == null) return const Scaffold(body: SizedBox());
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;
    final ar = app.isAr;
    final space = app.space(project.spaceId);
    final tone = toneColors(c, space?.tone ?? Tone.slate);
    final st = app.stats(project.id);
    final all = app.tasksOfProject(project.id);
    final active = all.where((x) => !x.isDone).toList()..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    final done = all.where((x) => x.isDone).toList()..sort((a, b) => b.sortKey.compareTo(a.sortKey));
    final list = switch (_tab) { 1 => active, 2 => done, _ => [...active, ...done] };
    void addTask() => push(context, TaskFormScreen(projectId: project.id));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(
              title: t['projectDetails'],
              trailing: FbIconButton(
                icon: Icons.more_horiz_rounded,
                label: t['more'],
                onTap: () => showActionsSheet(context, [
                  SheetAction(Icons.add_rounded, t['addTaskA'], addTask),
                  SheetAction(Icons.delete_outline_rounded, t['deleteProjectA'], _delete, danger: true),
                ]),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 28),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconTile(icon: FbIcons.of(project.icon), bg: tone.bg, fg: tone.fg, size: 48, iconSize: 24),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    header: true,
                    child: Text(project.name.of(ar),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.4, color: c.text)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (space != null)
                      _Pill(
                        icon: FbIcons.of(space.icon),
                        label: space.name.of(ar),
                        bg: tone.bg,
                        fg: tone.fg,
                        onTap: () => openSpace(context, space.id),
                      ),
                    _Pill(icon: Icons.calendar_today_outlined, label: f.due(project.due), bg: c.surface, fg: c.text2, border: c.border),
                  ]),
                  const SizedBox(height: 18),
                  FbCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: Text(t['progress'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text2))),
                            Text('${st.percent}%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: c.text)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FbProgressBar(value: st.ratio, height: 6),
                        const SizedBox(height: 12),
                        Wrap(spacing: 18, runSpacing: 6, children: [
                          _InlineStat(dot: c.borderStrong, value: st.total, label: t['statTasks']),
                          _InlineStat(dot: c.primary, value: st.done, label: t['completed']),
                          _InlineStat(dot: c.warning, value: st.remaining, label: t['remaining']),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SegmentedTabs(
                    labels: [t['fAll'], t['fActive'], t['fCompleted']],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: 14),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(t['noTasksHere'], textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.text2)),
                    )
                  else
                    for (final task in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TaskCard(key: ValueKey(task.id), task: task, mode: WhenMode.date),
                      ),
                  if (!project.notes.isEmpty) ...[
                    const SizedBox(height: 8),
                    FbCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.sticky_note_2_outlined, size: 16, color: c.text2),
                            const SizedBox(width: 6),
                            Text(t['projectNotes'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text2)),
                          ]),
                          const SizedBox(height: 6),
                          Text(project.notes.of(ar), style: FbText.body(c.text)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(child: PrimaryButton(label: t['addTask'], icon: Icons.add_rounded, onPressed: addTask)),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.bg, required this.fg, this.border, this.onTap});
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: border == null ? BorderSide.none : BorderSide(color: border!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.dot, required this.value, required this.label});
  final Color dot;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$value ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
      Text(label, style: TextStyle(fontSize: 13, color: c.text2)),
    ]);
  }
}
