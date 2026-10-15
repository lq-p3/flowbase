import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../data/models.dart';
import '../navigation.dart';
import '../widgets/controls.dart';
import '../widgets/fb_icons.dart';
import '../widgets/layout.dart';
import '../widgets/overlays.dart';
import 'space_detail_screen.dart';

class SpaceFormScreen extends StatefulWidget {
  const SpaceFormScreen({super.key});
  @override
  State<SpaceFormScreen> createState() => _SpaceFormScreenState();
}

class _SpaceFormScreenState extends State<SpaceFormScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  String _icon = 'briefcase';
  Tone _tone = Tone.indigo;
  bool _err = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _err = true);
      return;
    }
    final app = context.appRead;
    final space = Space(
      id: app.newId('sp'),
      name: LText.same(name),
      icon: _icon,
      tone: _tone,
      description: LText.same(_desc.text.trim()),
    );
    app.addSpace(space);
    replace(context, SpaceDetailScreen(spaceId: space.id));
    showToast(context.s['spaceCreated']);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;
    final tone = toneColors(c, _tone);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(title: t['createSpace'], close: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 28),
                children: [
                  // Live preview
                  ExcludeSemantics(
                    child: FbCard(
                      child: Row(children: [
                        IconTile(icon: FbIcons.of(_icon), bg: tone.bg, fg: tone.fg, size: 48, iconSize: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_name.text.trim().isEmpty ? t['newSpace'] : _name.text.trim(),
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.text)),
                            const SizedBox(height: 3),
                            Text('${f.nProjects(0)} · ${f.nActive(0)}', style: TextStyle(fontSize: 13, color: c.text2)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FbTextField(
                    controller: _name,
                    label: t['spaceName'],
                    hint: t['spaceNamePh'],
                    autofocus: true,
                    error: _err ? t['nameErr'] : null,
                    onChanged: (_) => setState(() => _err = false),
                  ),
                  const SizedBox(height: 22),
                  FbTextField(controller: _desc, label: t['description'], hint: t['spaceDescPh'], maxLines: 3, minLines: 2),
                  const SizedBox(height: 22),
                  Text(t['icon'], style: FbText.label(c.text)),
                  const SizedBox(height: 10),
                  IconChoiceGrid(choices: FbIcons.spaceChoices, value: _icon, onChanged: (v) => setState(() => _icon = v)),
                  const SizedBox(height: 22),
                  Text(t['color'], style: FbText.label(c.text)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final tn in Tone.values)
                        Semantics(
                          button: true,
                          selected: _tone == tn,
                          label: t['tone_${tn.name}'],
                          child: GestureDetector(
                            onTap: () => setState(() => _tone = tn),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _tone == tn ? toneColors(c, tn).solid : Colors.transparent, width: 2),
                              ),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(color: toneColors(c, tn).solid, shape: BoxShape.circle),
                                child: _tone == tn ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(child: PrimaryButton(label: t['createSpace'], onPressed: _save)),
    );
  }
}

/// 4×2 grid of curated icons (Space and Project forms).
class IconChoiceGrid extends StatelessWidget {
  const IconChoiceGrid({super.key, required this.choices, required this.value, required this.onChanged});
  final List<String> choices;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    Widget cell(String k) {
      final sel = k == value;
      return Semantics(
        button: true,
        selected: sel,
        label: '${context.s['icon']} $k',
        child: GestureDetector(
          onTap: () => onChanged(k),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 52,
            decoration: BoxDecoration(
              color: sel ? c.primaryLight : c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sel ? c.primary : c.border, width: 1.5),
            ),
            child: Icon(FbIcons.of(k), size: 22, color: sel ? c.primaryText : c.text2),
          ),
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < choices.length; i += 4) {
      if (i > 0) rows.add(const SizedBox(height: 8));
      rows.add(Row(children: [
        for (var j = i; j < i + 4; j++) ...[
          if (j > i) const SizedBox(width: 8),
          Expanded(child: j < choices.length ? cell(choices[j]) : const SizedBox()),
        ],
      ]));
    }
    return Column(children: rows);
  }
}
