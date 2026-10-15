import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../data/models.dart';
import '../navigation.dart';
import '../state/app_state.dart';
import '../widgets/controls.dart';
import '../widgets/fb_icons.dart';
import '../widgets/layout.dart';
import '../widgets/overlays.dart';
import 'project_detail_screen.dart';
import 'space_form_screen.dart' show IconChoiceGrid;

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key, this.spaceId});
  final String? spaceId;
  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  late String _spaceId;
  DateTime _due = kToday.add(const Duration(days: 30));
  String _icon = 'folder';
  bool _err = false;

  @override
  void initState() {
    super.initState();
    final app = context.appRead;
    _spaceId = app.space(widget.spaceId)?.id ?? (app.spaces.isNotEmpty ? app.spaces.first.id : '');
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final p = await showDatePicker(context: context, initialDate: _due, firstDate: DateTime(2025), lastDate: DateTime(2028));
    if (p != null) setState(() => _due = DateTime.utc(p.year, p.month, p.day));
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _err = true);
      return;
    }
    final app = context.appRead;
    final project = Project(
      id: app.newId('pr'),
      spaceId: _spaceId,
      name: LText.same(name),
      due: _due,
      icon: _icon,
      notes: LText.same(_desc.text.trim()),
    );
    app.addProject(project);
    replace(context, ProjectDetailScreen(projectId: project.id));
    showToast(context.s['projectCreated']);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;
    final ar = app.isAr;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(title: t['createProject'], close: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 28),
                children: [
                  FbTextField(
                    controller: _name,
                    label: t['projectName'],
                    hint: t['projectNamePh'],
                    autofocus: true,
                    error: _err ? t['nameErr'] : null,
                    onChanged: (_) {
                      if (_err) setState(() => _err = false);
                    },
                  ),
                  const SizedBox(height: 22),
                  FbTextField(controller: _desc, label: t['description'], hint: t['projectDescPh'], maxLines: 4, minLines: 3),
                  const SizedBox(height: 22),
                  Text(t['space'], style: FbText.label(c.text)),
                  const SizedBox(height: 10),
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
                          onTap: () => setState(() => _spaceId = s.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(t['dueDate'], style: FbText.label(c.text)),
                  const SizedBox(height: 10),
                  FbCard(
                    onTap: _pickDue,
                    radius: Rad.input,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(children: [
                      Icon(Icons.calendar_today_outlined, size: 19, color: c.text2),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f.full(_due), style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: c.text))),
                      Icon(Icons.expand_more_rounded, size: 20, color: c.muted),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  Row(children: [
                    Text(t['projectIcon'], style: FbText.label(c.text)),
                    Text('  ·  ${t['optional']}', style: TextStyle(fontSize: 13, color: c.text2)),
                  ]),
                  const SizedBox(height: 10),
                  IconChoiceGrid(choices: FbIcons.projectChoices, value: _icon, onChanged: (v) => setState(() => _icon = v)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(child: PrimaryButton(label: t['createProject'], onPressed: _save)),
    );
  }
}
