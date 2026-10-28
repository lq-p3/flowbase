import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../data/models.dart';
import '../navigation.dart';
import '../state/app_state.dart';
import '../widgets/controls.dart';
import '../widgets/layout.dart';
import '../widgets/overlays.dart';
import 'assistant_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// Answers one question: "What should I focus on today?"
/// The secretary comes first (summary + ask box), then today's schedule, then anything overdue.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ask = TextEditingController();

  @override
  void dispose() {
    _ask.dispose();
    super.dispose();
  }

  void _openSecretary([String? message]) {
    _ask.clear();
    push(context, AssistantScreen(initialMessage: message));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;
    final ar = app.isAr;

    final today = app.tasksOn(kToday);
    int byTime(Task a, Task b) => (a.time ?? '99:99').compareTo(b.time ?? '99:99');
    final open = today.where((x) => !x.isDone).toList()..sort(byTime);
    final ordered = [...today]..sort(byTime);
    final done = today.length - open.length;
    final overdue = app.tasks.where((x) => !x.isDone && x.date.isBefore(kToday)).length;
    final next = open.isEmpty ? null : open.first;

    // The summary is written here on the phone (no AI call), so it is instant and free.
    String summary;
    if (today.isEmpty) {
      summary = t['secEmpty'];
    } else if (next == null) {
      summary = t['secAllDone'];
    } else {
      summary = '${t['secTasks'].replaceAll('{n}', '${today.length}')} ${t['secNext'].replaceAll('{task}', next.title.of(ar))}';
      if (next.time != null) summary += t['secAt'].replaceAll('{time}', f.time(next.time));
      summary += '.';
    }
    if (overdue > 0) summary += t['secOverdue'].replaceAll('{n}', '$overdue');

    final name = app.userName.split(' ').first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Sp.page, 16, Sp.page, 28),
      children: [
        // Header: date, greeting, search, profile
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.long(kToday), style: TextStyle(fontSize: 13, color: c.text2)),
                  const SizedBox(height: 2),
                  Semantics(header: true, child: Text(name.isEmpty ? t['greet'] : t['greetName'].replaceAll('{name}', name), style: FbText.greeting(c.text))),
                ],
              ),
            ),
            FbIconButton(icon: Icons.search_rounded, label: t['search'], onTap: () => push(context, const SearchScreen())),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: t['profile'],
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => push(context, const ProfileScreen()),
                child: const ExcludeSemantics(child: Avatar()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // The secretary card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(t['secretary'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(230))),
              ]),
              const SizedBox(height: 12),
              Text(summary, style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w500, color: Colors.white)),
              const SizedBox(height: 14),
              Container(
                height: 48,
                padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
                decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ask,
                        style: const TextStyle(fontSize: 15, color: Colors.white),
                        cursorColor: Colors.white,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (v) => _openSecretary(v),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: t['secAsk'],
                          hintStyle: TextStyle(fontSize: 15, color: Colors.white.withAlpha(190)),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: t['secSend'],
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _openSecretary(_ask.text),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(Icons.arrow_forward_rounded, size: 18, color: c.primaryDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Today's schedule
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Semantics(header: true, child: Text(t['schedule'], style: FbText.section(c.text)))),
            if (today.isNotEmpty) Text(t['doneOf'].replaceAll('{d}', '$done').replaceAll('{n}', '${today.length}'), style: TextStyle(fontSize: 13, color: c.text2)),
          ],
        ),
        if (today.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: done / today.length, minHeight: 6, color: c.primary, backgroundColor: c.border),
          ),
        ],
        const SizedBox(height: 12),
        if (today.isEmpty)
          EmptyState(
            icon: Icons.check_circle_outline_rounded,
            iconBg: c.successBg,
            iconFg: c.successText,
            title: t['caughtUp'],
            message: t['caughtUpSub'],
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                for (var i = 0; i < ordered.length; i++)
                  _ScheduleRow(task: ordered[i], isNext: ordered[i] == next, last: i == ordered.length - 1),
              ],
            ),
          ),

        // Overdue
        if (overdue > 0) ...[
          const SizedBox(height: 12),
          Material(
            color: c.warningBg,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openSecretary(t['sortPrompt']),
              child: SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 18, color: c.warningText),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t['overdueN'].replaceAll('{n}', '$overdue'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.warningText))),
                      Text(t['sortForMe'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.warningText)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One line of today's schedule: time · check · title (space · project) · tag.
class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.task, required this.isNext, required this.last});
  final Task task;
  final bool isNext, last;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;
    final ar = app.isAr;
    final done = task.isDone;
    final title = task.title.of(ar);
    final meta = [app.space(task.spaceId)?.name.of(ar), app.project(task.projectId)?.name.of(ar)].whereType<String>().join(' · ');
    final high = task.priority == Priority.high || task.priority == Priority.urgent;

    return InkWell(
      onTap: () => openTask(context, task.id),
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.border))),
        child: Row(
          children: [
            SizedBox(
              width: 62,
              child: Text(
                f.time(task.time),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                  color: isNext ? c.primaryText : (done ? c.muted : c.text2),
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: c.muted,
                ),
              ),
            ),
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
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                    if (!done && meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.text2)),
                    ],
                  ],
                ),
              ),
            ),
            if (isNext)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: c.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: Text(t['nowTag'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.primaryText)),
              )
            else if (high && !done)
              Semantics(
                label: t['highPriority'],
                child: Container(width: 8, height: 8, margin: const EdgeInsetsDirectional.only(end: 4), decoration: BoxDecoration(color: c.warning, shape: BoxShape.circle)),
              ),
          ],
        ),
      ),
    );
  }
}
