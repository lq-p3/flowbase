import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../data/models.dart';
import '../navigation.dart';
import '../widgets/controls.dart';
import '../widgets/fb_icons.dart';
import '../widgets/layout.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});
  final String initialQuery;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _Result {
  _Result(this.title, this.meta, this.icon, this.bg, this.fg, this.open);
  final String title;
  final String meta;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback open;
}

class _SearchScreenState extends State<SearchScreen> {
  late final _q = TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  bool _match(LText text, String q) => text.contains(q);

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    final f = context.fmt;
    final ar = app.isAr;
    final query = _q.text.trim();
    final q = query.toLowerCase();

    void go(VoidCallback open) {
      context.appRead.rememberSearch(query);
      open();
    }

    final groups = <(String, List<_Result>)>[];
    if (q.isNotEmpty) {
      final tasks = app.tasks.where((x) => _match(x.title, q)).toList()
        ..sort((a, b) {
          if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
          return a.sortKey.compareTo(b.sortKey);
        });
      final taskResults = [
        for (final x in tasks.take(5))
          _Result(
            x.title.of(ar),
            [app.space(x.spaceId)?.name.of(ar), app.project(x.projectId)?.name.of(ar), f.rel(x.date)].whereType<String>().join(' · '),
            x.isDone ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded,
            x.isDone ? c.successBg : c.surface2,
            x.isDone ? c.successText : c.text2,
            () => go(() => openTask(context, x.id)),
          ),
      ];
      final projectResults = [
        for (final p in app.projects.where((p) => _match(p.name, q)))
          () {
            final tone = toneColors(c, app.space(p.spaceId)?.tone ?? Tone.slate);
            return _Result(p.name.of(ar), '${app.space(p.spaceId)?.name.of(ar) ?? ''} · ${app.stats(p.id).percent}%', FbIcons.of(p.icon),
                tone.bg, tone.fg, () => go(() => openProject(context, p.id)));
          }(),
      ];
      final spaceResults = [
        for (final s in app.spaces.where((s) => _match(s.name, q)))
          () {
            final tone = toneColors(c, s.tone);
            return _Result(s.name.of(ar), '${f.nProjects(app.projectsIn(s.id).length)} · ${f.nActive(app.activeIn(s.id))}', FbIcons.of(s.icon),
                tone.bg, tone.fg, () => go(() => openSpace(context, s.id)));
          }(),
      ];
      if (taskResults.isNotEmpty) groups.add((t['tasks'], taskResults));
      if (projectResults.isNotEmpty) groups.add((t['projects'], projectResults));
      if (spaceResults.isNotEmpty) groups.add((t['spaces'], spaceResults));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: [
                  FbIconButton(
                    icon: Icons.chevron_left_rounded,
                    iconSize: 28,
                    directional: true,
                    label: t['back'],
                    onTap: () => Navigator.maybePop(context),
                  ),
                  Semantics(header: true, child: Text(t['searchTitle'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text))),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.page, 4, Sp.page, 0),
              child: FbSearchField(controller: _q, hint: t['searchPh'], autofocus: widget.initialQuery.isEmpty, highlight: true, onChanged: (_) => setState(() {})),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.page, 20, Sp.page, 28),
                children: [
                  if (q.isEmpty && app.recent.isNotEmpty) ...[
                    CapsLabel(t['recent'], trailing: FbTextButton(label: t['clear'], size: 13, onTap: () => context.appRead.clearRecent())),
                    for (final r in app.recent)
                      InkWell(
                        onTap: () => setState(() => _q.text = r),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                          child: Row(children: [
                            Icon(Icons.history_rounded, size: 19, color: c.muted),
                            const SizedBox(width: 12),
                            Expanded(child: Text(r, style: TextStyle(fontSize: 15, color: c.text))),
                            DirIcon(Icons.north_west_rounded, size: 17, color: c.muted),
                          ]),
                        ),
                      ),
                  ],
                  for (final g in groups) ...[
                    CapsLabel('${g.$1}  ${g.$2.length}'),
                    GroupCard(children: [for (final r in g.$2) _ResultRow(result: r, query: query)]),
                    const SizedBox(height: 20),
                  ],
                  if (q.isNotEmpty && groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        bordered: false,
                        iconBg: c.surface2,
                        iconFg: c.text2,
                        title: t['noResults'],
                        message: t['noResultsSub'],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result, required this.query});
  final _Result result;
  final String query;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final base = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.35, color: c.text);
    final i = result.title.toLowerCase().indexOf(query.toLowerCase());
    final spans = i < 0 || query.isEmpty
        ? [TextSpan(text: result.title)]
        : [
            TextSpan(text: result.title.substring(0, i)),
            TextSpan(
              text: result.title.substring(i, i + query.length),
              style: TextStyle(fontWeight: FontWeight.w700, color: c.primaryText, backgroundColor: c.primaryLight),
            ),
            TextSpan(text: result.title.substring(i + query.length)),
          ];
    return InkWell(
      onTap: result.open,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          IconTile(icon: result.icon, bg: result.bg, fg: result.fg, size: 36, iconSize: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(style: base, children: spans)),
              const SizedBox(height: 2),
              Text(result.meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.text2)),
            ]),
          ),
          const SizedBox(width: 8),
          DirIcon(Icons.chevron_right_rounded, size: 18, color: c.muted),
        ]),
      ),
    );
  }
}
