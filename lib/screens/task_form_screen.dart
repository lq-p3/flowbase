import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/controls.dart';
import '../widgets/fb_icons.dart';
import '../widgets/layout.dart';
import '../widgets/overlays.dart';

/// Create Task — or Edit Task when [taskId] is given.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.taskId, this.projectId, this.spaceId, this.date});
  final String? taskId;
  final String? projectId;
  final String? spaceId;
  final DateTime? date;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _sub = TextEditingController();
  late String _spaceId;
  String? _projectId;
  late DateTime _date;
  String? _time;
  Priority _prio = Priority.medium;
  List<SubTask> _subs = [];
  bool _reminder = true;
  bool _err = false;
  Task? _editing;

  @override
  void initState() {
    super.initState();
    final app = context.appRead;
    final ar = app.isAr;
    _editing = app.task(widget.taskId);
    final e = _editing;
    if (e != null) {
      _title.text = e.title.of(ar);
      _desc.text = e.description.of(ar);
      _spaceId = e.spaceId;
      _projectId = e.projectId;
      _date = e.date;
      _time = e.time;
      _prio = e.priority;
      _subs = [for (final s in e.subtasks) s.copy()];
      _reminder = e.reminder;
    } else {
      final p = app.project(widget.projectId);
      _projectId = p?.id;
      _spaceId = p?.spaceId ?? widget.spaceId ?? (app.spaces.isNotEmpty ? app.spaces.first.id : '');
      _date = widget.date ?? kToday;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _sub.dispose();
    super.dispose();
  }

  void _addSub() {
    final v = _sub.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _subs.add(SubTask(id: context.appRead.newId('s'), title: LText.same(v)));
      _sub.clear();
    });
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2025), lastDate: DateTime(2028));
    if (p != null) setState(() => _date = DateTime.utc(p.year, p.month, p.day));
  }

  Future<void> _pickTime() async {
    final parts = (_time ?? '09:00').split(':');
    final p = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
    if (p != null) {
      setState(() => _time = '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}');
    }
  }

  void _save() {
    final app = context.appRead;
    final t = context.s;
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _err = true);
      return;
    }
    final e = _editing;
    final ar = app.isAr;
    if (e != null) {
      // Keep the other language's text unless the user changed it.
      final titleChanged = title != e.title.of(ar);
      final descChanged = _desc.text != e.description.of(ar);
      app.saveTask(Task(
        id: e.id,
        title: titleChanged ? LText.same(title) : e.title,
        description: descChanged ? LText.same(_desc.text.trim()) : e.description,
        notes: e.notes,
        spaceId: _spaceId,
        projectId: _projectId,
        date: _date,
        time: _time,
        priority: _prio,
        status: e.status,
        subtasks: _subs,
        reminder: _reminder,
      ));
      Navigator.pop(context);
      showToast(t['changesSaved']);
    } else {
      app.saveTask(Task(
        id: app.newId('t'),
        title: LText.same(title),
        description: LText.same(_desc.text.trim()),
        spaceId: _spaceId,
        projectId: _projectId,
        date: _date,
        time: _time,
        priority: _prio,
        subtasks: _subs,
        reminder: _reminder,
      ));
      Navigator.pop(context);
      showToast(t['taskCreated']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;
    final ar = app.isAr;
    final projects = app.projectsIn(_spaceId);

    Widget label(String text, {bool optional = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Text(text, style: FbText.label(c.text)),
            if (optional) Text('  ·  ${t['optional']}', style: TextStyle(fontSize: 13, color: c.text2)),
          ]),
        );

    Widget pickerTile(IconData icon, String value, VoidCallback onTap, {bool placeholder = false}) => FbCard(
          onTap: onTap,
          radius: Rad.input,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            Icon(icon, size: 19, color: c.text2),
            const SizedBox(width: 10),
            Expanded(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.5, color: placeholder ? c.muted : c.text, fontWeight: FontWeight.w500)),
            ),
          ]),
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(title: _editing != null ? t['editTask'] : t['createTask'], close: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 28),
                children: [
                  FbTextField(
                    controller: _title,
                    label: t['taskTitle'],
                    hint: t['titlePh'],
                    autofocus: _editing == null,
                    error: _err ? t['titleErr'] : null,
                    onChanged: (_) {
                      if (_err) setState(() => _err = false);
                    },
                  ),
                  const SizedBox(height: 22),
                  FbTextField(controller: _desc, label: t['description'], hint: t['descPh'], maxLines: 4, minLines: 3),
                  const SizedBox(height: 22),
                  label(t['space']),
                  TwoColumnGrid(
                    gap: 8,
                    children: [
                      for (final s in app.spaces)
                        FbChip(
                          label: s.name.of(ar),
                          icon: FbIcons.of(s.icon),
                          showCheck: false,
                          height: 46,
                          selected: _spaceId == s.id,
                          onTap: () => setState(() {
                            if (_spaceId != s.id) _projectId = null;
                            _spaceId = s.id;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  label(t['project']),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FbChip(label: t['noProject'], selected: _projectId == null, onTap: () => setState(() => _projectId = null)),
                      for (final p in projects)
                        FbChip(label: p.name.of(ar), selected: _projectId == p.id, onTap: () => setState(() => _projectId = p.id)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          label(t['dueDate']),
                          pickerTile(Icons.calendar_today_outlined, f.rel(_date), _pickDate),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          label(t['dueTime']),
                          pickerTile(Icons.schedule_rounded, _time == null ? t['noTimeSet'] : f.time(_time), _pickTime, placeholder: _time == null),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  label(t['priority']),
                  Row(
                    children: [
                      for (final p in Priority.values) ...[
                        if (p != Priority.low) const SizedBox(width: 8),
                        Expanded(child: _PriorityChoice(priority: p, selected: _prio == p, onTap: () => setState(() => _prio = p))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  label(t['subtasks'], optional: true),
                  if (_subs.isNotEmpty) ...[
                    GroupCard(children: [
                      for (final s in _subs)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 14),
                          child: Row(children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: c.borderStrong, width: 1.6)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(s.title.of(ar), style: TextStyle(fontSize: 14.5, color: c.text))),
                            FbIconButton(
                              icon: Icons.close_rounded,
                              iconSize: 18,
                              label: t['removeSub'],
                              foreground: c.text2,
                              onTap: () => setState(() => _subs.remove(s)),
                            ),
                          ]),
                        ),
                    ]),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: FbTextField(controller: _sub, hint: t['subPh'], onSubmitted: (_) => _addSub(), textInputAction: TextInputAction.done),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _addSub,
                          style: FilledButton.styleFrom(
                            backgroundColor: c.primaryLight,
                            foregroundColor: c.primaryText,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(t['addSubtask'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  FbCard(
                    padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
                    child: Row(children: [
                      IconTile(icon: Icons.notifications_none_rounded, bg: c.primaryLight, fg: c.primaryText, size: 36, iconSize: 19),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t['reminder'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
                          const SizedBox(height: 2),
                          Text(t['reminderSub'], style: TextStyle(fontSize: 13, color: c.text2)),
                        ]),
                      ),
                      FbSwitch(value: _reminder, onChanged: (v) => setState(() => _reminder = v)),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(label: _editing != null ? t['saveChanges'] : t['createTask'], onPressed: _save),
      ),
    );
  }
}

class _PriorityChoice extends StatelessWidget {
  const _PriorityChoice({required this.priority, required this.selected, required this.onTap});
  final Priority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final (bg, fg) = priorityColors(c, priority);
    final border = priority == Priority.urgent ? c.dangerSolid : fg;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? bg : c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? border : c.border, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_outlined, size: 13, color: selected ? fg : c.text2),
              const SizedBox(width: 4),
              Flexible(
                child: Text(context.s[priority.name],
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? fg : c.text)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
