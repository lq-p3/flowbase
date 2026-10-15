import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../data/models.dart';
import '../navigation.dart';
import '../widgets/controls.dart';
import '../widgets/fb_icons.dart';
import '../widgets/layout.dart';
import '../widgets/overlays.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _sub = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final t = context.s;
    final ok = await showConfirm(context, title: t['dTaskT'], message: t['dTaskM']);
    if (!ok || !mounted) return;
    final app = context.appRead;
    Navigator.pop(context);
    app.deleteTask(widget.taskId);
    showToast(t['taskDeleted'], icon: Icons.delete_outline_rounded);
  }

  void _addSub() {
    context.appRead.addSub(widget.taskId, _sub.text);
    if (_sub.text.trim().isNotEmpty) showToast(context.s['subtaskAdded']);
    _sub.clear();
    setState(() => _adding = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final task = app.task(widget.taskId);
    if (task == null) return const Scaffold(body: SizedBox()); // deleted while closing
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;
    final ar = app.isAr;
    final space = app.space(task.spaceId);
    final project = app.project(task.projectId);
    final tone = toneColors(c, space?.tone ?? Tone.slate);
    final done = task.isDone;
    final subsDone = task.subtasks.where((s) => s.done).length;

    void toggle() {
      if (app.toggleTask(task.id)) showToast(t['taskCompleted']);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(
              title: t['taskDetails'],
              trailing: FbIconButton(
                icon: Icons.more_horiz_rounded,
                label: t['more'],
                onTap: () => showActionsSheet(context, [
                  SheetAction(Icons.edit_outlined, t['editTaskA'], () => push(context, TaskFormScreen(taskId: task.id))),
                  SheetAction(Icons.delete_outline_rounded, t['deleteTaskA'], _delete, danger: true),
                ]),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 28),
                children: [
                  // Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: Offset(context.isRtl ? 10 : -10, 0),
                        child: FbCheckbox(
                          checked: done,
                          size: 26,
                          inProgress: task.status == TaskStatus.inProgress,
                          semanticLabel: done ? t['markIncomplete'] : t['markCompleted'],
                          onTap: toggle,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Semantics(
                            header: true,
                            child: Text(
                              task.title.of(ar),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                letterSpacing: -0.3,
                                color: done ? c.text2 : c.text,
                                decoration: done ? TextDecoration.lineThrough : null,
                                decorationColor: c.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    PriorityBadge(priority: task.priority, large: true),
                    StatusBadge(
                      status: task.status,
                      onTap: () {
                        if (app.cycleStatus(task.id)) showToast(t['taskCompleted']);
                      },
                    ),
                  ]),
                  const SizedBox(height: 18),

                  // Information
                  GroupCard(children: [
                    ListRow(
                      icon: FbIcons.of(space?.icon),
                      label: t['space'],
                      value: space?.name.of(ar) ?? '',
                      valueDot: tone.fg,
                      onTap: space == null ? null : () => openSpace(context, space.id),
                    ),
                    ListRow(
                      icon: Icons.folder_outlined,
                      label: t['project'],
                      value: project?.name.of(ar) ?? t['noProject'],
                      onTap: project == null ? null : () => openProject(context, project.id),
                    ),
                    ListRow(icon: Icons.calendar_today_outlined, label: t['dueDate'], value: f.relLong(task.date)),
                    ListRow(icon: Icons.schedule_rounded, label: t['time'], value: task.time == null ? t['anytime'] : f.time(task.time)),
                  ]),

                  // Description
                  if (!task.description.isEmpty) ...[
                    const SizedBox(height: 20),
                    Text(t['description'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text2)),
                    const SizedBox(height: 8),
                    Text(task.description.of(ar), style: FbText.body(c.text)),
                  ],

                  // Subtasks
                  const SizedBox(height: 20),
                  FbCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(child: Text(t['subtasks'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text))),
                          if (task.subtasks.isNotEmpty)
                            Text(f.subsOf(subsDone, task.subtasks.length), style: TextStyle(fontSize: 13, color: c.text2)),
                        ]),
                        const SizedBox(height: 12),
                        if (task.subtasks.isEmpty)
                          Text(t['noSubs'], style: TextStyle(fontSize: 14, height: 1.45, color: c.text2))
                        else ...[
                          FbProgressBar(value: subsDone / task.subtasks.length, color: c.success),
                          const SizedBox(height: 6),
                          for (final s in task.subtasks)
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => app.toggleSub(task.id, s.id),
                              child: Semantics(
                                checked: s.done,
                                child: SizedBox(
                                  height: 44,
                                  child: Row(children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: s.done ? c.success : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: s.done ? c.success : c.borderStrong, width: 1.8),
                                      ),
                                      child: s.done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        s.title.of(ar),
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          color: s.done ? c.text2 : c.text,
                                          decoration: s.done ? TextDecoration.lineThrough : null,
                                          decorationColor: c.muted,
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 10),
                        if (_adding)
                          Row(children: [
                            Expanded(child: FbTextField(controller: _sub, hint: t['subPh'], autofocus: true, onSubmitted: (_) => _addSub())),
                            const SizedBox(width: 8),
                            PrimaryButton(label: t['add'], onPressed: _addSub, expand: false, height: 50),
                            FbIconButton(icon: Icons.close_rounded, label: t['cancel'], foreground: c.text2, onTap: () => setState(() => _adding = false)),
                          ])
                        else
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              onPressed: () => setState(() => _adding = true),
                              style: TextButton.styleFrom(
                                backgroundColor: c.primaryLight,
                                foregroundColor: c.primaryText,
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: Text(t['addSubtask'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Notes
                  if (!task.notes.isEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(color: c.warningBg, borderRadius: BorderRadius.circular(Rad.card)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.sticky_note_2_outlined, size: 19, color: c.warningText),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t['notes'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.warningText)),
                            const SizedBox(height: 3),
                            Text(task.notes.of(ar), style: TextStyle(fontSize: 14, height: 1.5, color: c.text)),
                          ]),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            FbIconButton(
              icon: Icons.edit_outlined,
              label: t['edit'],
              bordered: true,
              size: 52,
              onTap: () => push(context, TaskFormScreen(taskId: task.id)),
            ),
            const SizedBox(width: 10),
            FbIconButton(
              icon: Icons.delete_outline_rounded,
              label: t['delete'],
              size: 52,
              background: c.dangerBg,
              foreground: c.dangerText,
              onTap: _delete,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: done
                  ? SecondaryButton(label: t['markIncomplete'], icon: Icons.undo_rounded, onPressed: toggle)
                  : PrimaryButton(label: t['markCompleted'], icon: Icons.check_rounded, onPressed: toggle),
            ),
          ],
        ),
      ),
    );
  }
}
