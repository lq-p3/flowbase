import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../data/models.dart';
import '../navigation.dart';
import '../state/app_state.dart';
import '../widgets/cards.dart';
import '../widgets/controls.dart';
import '../widgets/layout.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'space_form_screen.dart';

/// Answers one question: "What should I focus on today?"
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _day = kToday;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;

    final dayTasks = app.tasksOn(_day);
    int byTime(Task a, Task b) => (a.time ?? '99:99').compareTo(b.time ?? '99:99');
    final ordered = [
      ...dayTasks.where((x) => !x.isDone).toList()..sort(byTime),
      ...dayTasks.where((x) => x.isDone).toList()..sort(byTime),
    ];
    final done = dayTasks.where((x) => x.isDone).length;
    final inProgress = dayTasks.where((x) => x.status == TaskStatus.inProgress).length;
    final ratio = dayTasks.isEmpty ? 0.0 : done / dayTasks.length;
    final active = app.activeProjects;
    final isToday = sameDay(_day, kToday);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.page),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.long(kToday), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.text2)),
                    const SizedBox(height: 3),
                    Semantics(header: true, child: Text(app.userName.isEmpty ? t['greet'] : t['greetName'].replaceAll('{name}', app.userName.split(' ').first), style: FbText.greeting(c.text))),
                  ],
                ),
              ),
              FbIconButton(icon: Icons.search_rounded, label: t['search'], bordered: true, onTap: () => push(context, const SearchScreen())),
              const SizedBox(width: 8),
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
        ),
        const SizedBox(height: 20),

        // 5-day selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.page),
          child: Row(
            children: [
              for (var i = -1; i <= 3; i++) ...[
                if (i > -1) const SizedBox(width: 8),
                Expanded(child: _DayChip(day: kToday.add(Duration(days: i)), selected: sameDay(_day, kToday.add(Duration(days: i))), onTap: (d) => setState(() => _day = d))),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Compact overview
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.page),
          child: FbCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                ProgressRing(value: ratio),
                const SizedBox(width: 16),
                Expanded(
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        for (final s in [
                          ('${dayTasks.length}', t['statTasks']),
                          ('$done', t['statDone']),
                          ('$inProgress', t['statProg']),
                        ])
                          Expanded(
                            child: Container(
                              padding: const EdgeInsetsDirectional.only(start: 10),
                              decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: c.border))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.$1, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text)),
                                  const SizedBox(height: 2),
                                  Text(s.$2, style: TextStyle(fontSize: 12, height: 1.25, color: c.text2)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Active projects
        if (active.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionHeader(
            title: t['activeProjects'],
            action: t['seeAll'],
            onAction: () => context.appRead.setTab(3),
            padding: const EdgeInsets.symmetric(horizontal: Sp.page),
          ),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Sp.page),
              itemCount: active.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => Align(alignment: Alignment.topCenter, child: ProjectCard(project: active[i])),
            ),
          ),
        ],

        // My spaces
        const SizedBox(height: 14),
        SectionHeader(
          title: t['mySpaces'],
          action: t['seeAll'],
          onAction: () => context.appRead.setTab(3),
          padding: const EdgeInsets.symmetric(horizontal: Sp.page),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.page),
          child: app.spaces.isEmpty
              ? SecondaryButton(label: t['createSpace'], icon: Icons.add_rounded, onPressed: () => push(context, const SpaceFormScreen()))
              : TwoColumnGrid(children: [for (final s in app.spaces) SpaceTile(space: s)]),
        ),

        // Tasks for the selected day
        const SizedBox(height: 18),
        SectionHeader(
          title: isToday ? t['todaysTasks'] : f.relLong(_day),
          count: dayTasks.length,
          action: t['seeAll'],
          onAction: () => context.appRead.setTab(1),
          padding: const EdgeInsets.symmetric(horizontal: Sp.page),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.page),
          child: ordered.isEmpty
              ? EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  iconBg: c.successBg,
                  iconFg: c.successText,
                  title: t['caughtUp'],
                  message: t['caughtUpSub'],
                )
              : Column(
                  children: [
                    for (final task in ordered)
                      Padding(padding: const EdgeInsets.only(bottom: 10), child: TaskCard(key: ValueKey(task.id), task: task)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.selected, required this.onTap});
  final DateTime day;
  final bool selected;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final f = context.fmt;
    final hasTasks = app.tasksOn(day).any((x) => !x.isDone);
    return Semantics(
      button: true,
      selected: selected,
      label: f.long(day),
      child: GestureDetector(
        onTap: () => onTap(day),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 70,
          decoration: BoxDecoration(
            color: selected ? c.primary : c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? c.primary : c.border),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(f.weekdayShort(day),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: selected ? Colors.white.withAlpha(215) : c.text2)),
                const SizedBox(height: 4),
                Text('${day.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1, color: selected ? Colors.white : c.text)),
                const SizedBox(height: 5),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasTasks ? (selected ? Colors.white : c.primary) : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
