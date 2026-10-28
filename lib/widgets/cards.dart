import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../data/models.dart';
import '../navigation.dart';
import 'controls.dart';
import 'fb_icons.dart';
import 'overlays.dart';

enum WhenMode { time, date, none }

/// The one task card used on every screen (Home, Tasks, Calendar, Space, Project).
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.mode = WhenMode.time});
  final Task task;
  final WhenMode mode;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final f = context.fmt;
    final t = context.s;
    final ar = app.isAr;
    final space = app.space(task.spaceId);
    final project = app.project(task.projectId);
    final tone = toneColors(c, space?.tone ?? Tone.slate);
    final done = task.isDone;
    final title = task.title.of(ar);

    var when = '';
    if (mode == WhenMode.date) {
      when = f.rel(task.date);
      if (task.time != null) when += ', ${f.time(task.time)}';
    } else if (mode == WhenMode.time) {
      when = f.time(task.time);
    }
    final meta = [if (space != null) space.name.of(ar), if (project != null) project.name.of(ar)].join(' · ');

    return FbCard(
      onTap: () => openTask(context, task.id),
      padding: const EdgeInsetsDirectional.only(start: 2, end: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: FbCheckbox(
              checked: done,
              inProgress: task.status == TaskStatus.inProgress,
              semanticLabel: '${done ? t['markIncomplete'] : t['markCompleted']}: $title',
              onTap: () {
                if (context.appRead.toggleTask(task.id)) showToast(t['taskCompleted']);
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: done ? c.text2 : c.text,
                      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: c.muted,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: tone.fg, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(meta,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.text2)),
                      ),
                      if (when.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.schedule_rounded, size: 13, color: c.text2),
                        const SizedBox(width: 4),
                        Text(when, style: TextStyle(fontSize: 12.5, color: c.text2)),
                      ],
                      const SizedBox(width: 8),
                      PriorityBadge(priority: task.priority),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A group of tasks in one rounded box, separated by thin lines (the calm list style).
class TaskGroup extends StatelessWidget {
  const TaskGroup({super.key, required this.tasks, this.mode = WhenMode.time, this.inSpace = false, this.inProject = false});
  final List<Task> tasks;
  final WhenMode mode;

  /// Shown inside a space / project page, so that name is left out of each line.
  final bool inSpace, inProject;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          for (var i = 0; i < tasks.length; i++) TaskRow(key: ValueKey(tasks[i].id), task: tasks[i], mode: mode, last: i == tasks.length - 1, showSpace: !inSpace && !inProject, showProject: !inProject),
        ],
      ),
    );
  }
}

/// One line in a [TaskGroup]: check · title · "time · space · steps" · high-priority dot.
class TaskRow extends StatelessWidget {
  const TaskRow({super.key, required this.task, this.mode = WhenMode.time, this.last = false, this.showSpace = true, this.showProject = true});
  final Task task;
  final WhenMode mode;
  final bool last, showSpace, showProject;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final f = context.fmt;
    final t = context.s;
    final ar = app.isAr;
    final done = task.isDone;
    final title = task.title.of(ar);

    var when = '';
    if (mode == WhenMode.date) {
      when = f.rel(task.date);
      if (task.time != null) when += ', ${f.time(task.time)}';
    } else if (mode == WhenMode.time) {
      when = f.time(task.time);
    }
    final steps = task.subtasks.isEmpty ? null : '${task.subtasks.where((x) => x.done).length}/${task.subtasks.length}';
    final meta = [
      if (when.isNotEmpty) when,
      if (showSpace) app.space(task.spaceId)?.name.of(ar),
      if (showProject) app.project(task.projectId)?.name.of(ar),
      if (steps != null) steps,
    ].whereType<String>().join(' · ');
    final high = task.priority == Priority.high || task.priority == Priority.urgent;

    return InkWell(
      onTap: () => openTask(context, task.id),
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.border))),
        child: Row(
          children: [
            FbCheckbox(
              checked: done,
              inProgress: task.status == TaskStatus.inProgress,
              semanticLabel: '${done ? t['markIncomplete'] : t['markCompleted']}: $title',
              onTap: () {
                if (context.appRead.toggleTask(task.id)) showToast(t['taskCompleted']);
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: done ? FontWeight.w400 : FontWeight.w600,
                        height: 1.35,
                        color: done ? c.muted : c.text,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: c.muted,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: done ? c.muted : c.text2)),
                    ],
                  ],
                ),
              ),
            ),
            if (high && !done)
              Semantics(
                label: t['highPriority'],
                child: Container(width: 8, height: 8, margin: const EdgeInsetsDirectional.only(start: 8, end: 4), decoration: BoxDecoration(color: c.warning, shape: BoxShape.circle)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Wide card in Home's horizontally scrolling "Active Projects".
class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, this.width = 236});
  final Project project;
  final double width;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final f = context.fmt;
    final st = app.stats(project.id);
    final space = app.space(project.spaceId);
    final tone = toneColors(c, space?.tone ?? Tone.slate);
    return SizedBox(
      width: width,
      child: FbCard(
        onTap: () => openProject(context, project.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(icon: FbIcons.of(project.icon), bg: tone.bg, fg: tone.fg, size: 32, iconSize: 17),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(space?.name.of(app.isAr) ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.text2, fontWeight: FontWeight.w500)),
                ),
                Text('${st.percent}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: Text(project.name.of(app.isAr),
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3, color: c.text)),
            ),
            const SizedBox(height: 12),
            FbProgressBar(value: st.ratio),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 13, color: c.text2),
                const SizedBox(width: 5),
                Expanded(child: Text(f.due(project.due), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.text2))),
                Text(f.of(st.done, st.total), style: TextStyle(fontSize: 12.5, color: c.text2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width project row (Space details, search).
class ProjectRow extends StatelessWidget {
  const ProjectRow({super.key, required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final f = context.fmt;
    final st = app.stats(project.id);
    final tone = toneColors(c, app.space(project.spaceId)?.tone ?? Tone.slate);
    return FbCard(
      onTap: () => openProject(context, project.id),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              IconTile(icon: FbIcons.of(project.icon), bg: tone.bg, fg: tone.fg, size: 36, iconSize: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name.of(app.isAr), style: FbText.cardTitle(c.text)),
                    const SizedBox(height: 2),
                    Text('${f.due(project.due)} · ${f.of(st.done, st.total)}', style: TextStyle(fontSize: 12.5, color: c.text2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${st.percent}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
            ],
          ),
          const SizedBox(height: 12),
          FbProgressBar(value: st.ratio),
        ],
      ),
    );
  }
}

/// Compact space tile (Home "My Spaces").
class SpaceTile extends StatelessWidget {
  const SpaceTile({super.key, required this.space});
  final Space space;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final tone = toneColors(c, space.tone);
    return FbCard(
      onTap: () => openSpace(context, space.id),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconTile(icon: FbIcons.of(space.icon), bg: tone.bg, fg: tone.fg, size: 38, iconSize: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(space.name.of(app.isAr),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
                const SizedBox(height: 2),
                Text(context.fmt.nTasks(app.activeIn(space.id)), style: TextStyle(fontSize: 12.5, color: c.text2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Large card in the Spaces grid.
class SpaceCard extends StatelessWidget {
  const SpaceCard({super.key, required this.space});
  final Space space;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final f = context.fmt;
    final tone = toneColors(c, space.tone);
    return FbCard(
      onTap: () => openSpace(context, space.id),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(icon: FbIcons.of(space.icon), bg: tone.bg, fg: tone.fg, size: 44, iconSize: 22),
                const Spacer(),
                DirIcon(Icons.chevron_right_rounded, size: 20, color: c.muted),
              ],
            ),
            const SizedBox(height: 16),
            Text(space.name.of(app.isAr), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 6),
            Text(f.nProjects(app.projectsIn(space.id).length), style: TextStyle(fontSize: 13, color: c.text2)),
            const SizedBox(height: 2),
            Text(f.nActive(app.activeIn(space.id)), style: TextStyle(fontSize: 13, color: c.text2)),
          ],
        ),
      ),
    );
  }
}
