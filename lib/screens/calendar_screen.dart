import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../navigation.dart';
import '../state/app_state.dart';
import '../widgets/cards.dart';
import '../widgets/controls.dart';
import '../widgets/layout.dart';
import 'search_screen.dart';
import 'task_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime.utc(kToday.year, kToday.month, 1);
  DateTime _selected = kToday;

  void _shift(int n) => setState(() => _month = DateTime.utc(_month.year, _month.month + n, 1));

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;

    final daysInMonth = DateTime.utc(_month.year, _month.month + 1, 0).day;
    final lead = _month.weekday % 7; // Sunday-first grid
    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= daysInMonth; d++) DateTime.utc(_month.year, _month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final dayTasks = app.tasksOn(_selected)..sort((a, b) => (a.time ?? '99:99').compareTo(b.time ?? '99:99'));

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        PageHeader(
          title: t['calendar'],
          actions: [
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _selected = kToday;
                  _month = DateTime.utc(kToday.year, kToday.month, 1);
                }),
                style: OutlinedButton.styleFrom(
                  backgroundColor: c.surface,
                  side: BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(t['today'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
              ),
            ),
            FbIconButton(icon: Icons.search_rounded, label: t['search'], bordered: true, onTap: () => push(context, const SearchScreen())),
          ],
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.page),
          child: FbCard(
            radius: 20,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    FbIconButton(icon: Icons.chevron_left_rounded, iconSize: 24, directional: true, label: t['prevMonth'], onTap: () => _shift(-1)),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(f.month(_month.year, _month.month),
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)),
                      ),
                    ),
                    FbIconButton(icon: Icons.chevron_right_rounded, iconSize: 24, directional: true, label: t['nextMonth'], onTap: () => _shift(1)),
                  ],
                ),
                ExcludeSemantics(
                  child: SizedBox(
                    height: 28,
                    child: Row(
                      children: [
                        for (final w in f.weekdayMini)
                          Expanded(child: Text(w, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text2))),
                      ],
                    ),
                  ),
                ),
                for (var r = 0; r < cells.length; r += 7)
                  Row(
                    children: [
                      for (var i = r; i < r + 7; i++)
                        Expanded(child: cells[i] == null ? const SizedBox(height: 46) : _DayCell(day: cells[i]!, selected: sameDay(cells[i]!, _selected), onTap: (d) => setState(() => _selected = d))),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.page),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(f.full(_selected), style: FbText.section(c.text))),
              Text(f.nTasks(dayTasks.length), style: TextStyle(fontSize: 13, color: c.text2)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.page),
          child: dayTasks.isEmpty
              ? EmptyState(
                  icon: Icons.event_available_outlined,
                  title: t['nothingScheduled'],
                  message: t['nothingScheduledSub'],
                  actionLabel: t['addTask'],
                  onAction: () => push(context, TaskFormScreen(date: _selected)),
                )
              : Column(
                  children: [
                    for (var i = 0; i < dayTasks.length; i++)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 64,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: Text(
                                  dayTasks[i].time == null ? t['anytime'] : f.time(dayTasks[i].time),
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: dayTasks[i].isDone ? c.muted : c.text2),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 16,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  if (i != dayTasks.length - 1)
                                    Positioned(top: i == 0 ? 22 : 0, bottom: 0, child: Container(width: 1.5, color: c.border))
                                  else if (i != 0)
                                    Positioned(top: 0, height: 22, child: Container(width: 1.5, color: c.border)),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 21),
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: dayTasks[i].isDone ? c.muted : c.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: c.bg, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TaskCard(key: ValueKey(dayTasks[i].id), task: dayTasks[i], mode: WhenMode.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.selected, required this.onTap});
  final DateTime day;
  final bool selected;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final f = context.fmt;
    final tasks = app.tasksOn(day);
    final hasActive = tasks.any((x) => !x.isDone);
    final isToday = sameDay(day, kToday);
    return Semantics(
      button: true,
      selected: selected,
      label: tasks.isEmpty ? f.full(day) : '${f.full(day)}, ${f.nTasks(tasks.length)}',
      child: InkResponse(
        onTap: () => onTap(day),
        radius: 22,
        child: SizedBox(
          height: 46,
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? c.primary : Colors.transparent,
                    border: Border.all(color: isToday && !selected ? c.primary : Colors.transparent, width: 1.5),
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected || isToday ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : isToday ? c.primaryText : c.text,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tasks.isEmpty ? Colors.transparent : (hasActive ? c.primary : c.muted),
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

