import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../data/models.dart';
import '../navigation.dart';
import '../state/app_state.dart';
import '../widgets/cards.dart';
import '../widgets/controls.dart';
import '../widgets/layout.dart';
import '../widgets/overlays.dart';
import 'search_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _Group {
  _Group(this.label, this.tasks, this.mode);
  final String label;
  final List<Task> tasks;
  final WhenMode mode;
}

class _TasksScreenState extends State<TasksScreen> {
  final _q = TextEditingController();
  int _tab = 0; // 0 All · 1 Today · 2 Upcoming · 3 Completed

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<_Group> _groups(AppState app) {
    final f = context.fmt;
    final t = context.s;
    final q = _q.text.trim().toLowerCase();
    final list = app.tasks.where((x) => (q.isEmpty || x.title.contains(q)) && app.filters.matches(x, kToday)).toList();
    int byKey(Task a, Task b) => a.sortKey.compareTo(b.sortKey);

    List<_Group> byDate(Iterable<Task> items) {
      final map = <DateTime, List<Task>>{};
      for (final x in items.toList()..sort(byKey)) {
        map.putIfAbsent(dayOnly(x.date), () => []).add(x);
      }
      final days = map.keys.toList()..sort();
      return [for (final d in days) _Group(f.relLong(d), map[d]!, WhenMode.time)];
    }

    final done = list.where((x) => x.isDone).toList()..sort((a, b) => byKey(b, a));
    switch (_tab) {
      case 1:
        final today = list.where((x) => sameDay(x.date, kToday)).toList()..sort(byKey);
        final ordered = [...today.where((x) => !x.isDone), ...today.where((x) => x.isDone)];
        return ordered.isEmpty ? [] : [_Group(t['today'], ordered, WhenMode.time)];
      case 2:
        return byDate(list.where((x) => !x.isDone && x.date.isAfter(kToday)));
      case 3:
        return done.isEmpty ? [] : [_Group(t['completed'], done, WhenMode.date)];
      default:
        return [
          ...byDate(list.where((x) => !x.isDone)),
          if (done.isNotEmpty) _Group(t['completed'], done, WhenMode.date),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;
    final groups = _groups(app);
    final fc = app.filters.count;
    final narrowed = fc > 0 || _q.text.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Sp.page, 0, Sp.page, 28),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Expanded(child: Semantics(header: true, child: Text(t['allTasks'], style: FbText.pageTitle(c.text)))),
              FbIconButton(icon: Icons.search_rounded, label: t['search'], bordered: true, onTap: () => push(context, const SearchScreen())),
              const SizedBox(width: 8),
              FbIconButton(
                icon: Icons.tune_rounded,
                label: fc > 0 ? '${t['filters']} ($fc)' : t['filters'],
                bordered: true,
                background: fc > 0 ? c.primaryLight : null,
                foreground: fc > 0 ? c.primaryText : null,
                borderColor: fc > 0 ? c.primary : null,
                badge: fc > 0 ? '$fc' : null,
                onTap: () => showFiltersSheet(context),
              ),
              const SizedBox(width: 8),
              FbIconButton(icon: Icons.add_rounded, label: t['create'], background: c.primary, foreground: Colors.white, onTap: () => showCreateSheet(context)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FbSearchField(controller: _q, hint: t['searchTasks'], onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        SegmentedTabs(
          labels: [t['tabAll'], t['tabToday'], t['tabUpcoming'], t['tabCompleted']],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        if (fc > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 15, color: c.text2),
                const SizedBox(width: 6),
                Expanded(child: Text(f.filtersOn(fc), style: TextStyle(fontSize: 13, color: c.text2))),
                FbTextButton(label: t['clearFilters'], size: 13, onTap: () => context.appRead.setFilters(const TaskFilters())),
              ],
            ),
          ),
        for (final g in groups) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Semantics(header: true, child: Text(g.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text))),
              const SizedBox(width: 8),
              CountPill(count: g.tasks.length),
            ],
          ),
          const SizedBox(height: 10),
          for (final task in g.tasks)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: TaskCard(key: ValueKey(task.id), task: task, mode: g.mode)),
        ],
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: EmptyState(
              icon: Icons.inbox_outlined,
              bordered: false,
              title: narrowed ? t['noMatch'] : t['noTasksHere'],
              message: narrowed ? t['noMatchSub'] : t['noTasksSub'],
            ),
          ),
      ],
    );
  }
}
