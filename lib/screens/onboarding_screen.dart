import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../navigation.dart';
import '../widgets/controls.dart';
import 'auth_screens.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Sp.page, 12, Sp.page, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 32),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const BrandMark(),
                        const Spacer(),
                        _LangToggle(isAr: app.isAr, onChanged: (l) => context.appRead.setLang(l)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _HierarchyVisual(),
                    const SizedBox(height: 24),
                    Text(t['onb1'], style: TextStyle(fontSize: 30, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: c.text)),
                    Text(t['onb2'], style: TextStyle(fontSize: 30, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: c.primary)),
                    const SizedBox(height: 10),
                    Text(t['onbDesc'], style: TextStyle(fontSize: 15, height: 1.5, color: c.text2)),
                    const SizedBox(height: 20),
                    for (final b in [
                      (Icons.grid_view_rounded, t['ben1']),
                      (Icons.folder_outlined, t['ben2']),
                      (Icons.check_circle_outline_rounded, t['ben3']),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: c.border),
                              ),
                              child: Icon(b.$1, size: 17, color: c.primaryText),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(b.$2, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: c.text))),
                          ],
                        ),
                      ),
                    const Spacer(),
                    const SizedBox(height: 16),
                    PrimaryButton(label: t['getStarted'], onPressed: () => push(context, const SignUpScreen())),
                    const SizedBox(height: 10),
                    SecondaryButton(label: t['signIn'], onPressed: () => push(context, const SignInScreen())),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle({required this.isAr, required this.onChanged});
  final bool isAr;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    Widget seg(String code, String label) {
      final sel = (code == 'ar') == isAr;
      return Semantics(
        button: true,
        selected: sel,
        child: GestureDetector(
          onTap: () => onChanged(code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 36,
            constraints: const BoxConstraints(minWidth: 66),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: sel ? c.primary : Colors.transparent, borderRadius: BorderRadius.circular(9)),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : c.text2)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg('en', 'English'), const SizedBox(width: 2), seg('ar', 'العربية')]),
    );
  }
}

/// Abstract illustration of the Space → Project → Task hierarchy built from mini UI cards.
class _HierarchyVisual extends StatelessWidget {
  const _HierarchyVisual();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final f = context.fmt;
    final ar = app.isAr;
    final space = app.space('study');
    final project = app.project('ai');
    final task = app.task('t33');
    final shadow = [BoxShadow(color: const Color(0xFF17182B).withAlpha(18), blurRadius: 18, offset: const Offset(0, 6))];
    BoxDecoration card() => BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14), boxShadow: shadow);
    final done = task?.subtasks.where((s) => s.done).length ?? 0;
    final total = task?.subtasks.length ?? 0;
    final pct = project == null ? 0.0 : app.stats(project.id).ratio;

    return ExcludeSemantics(
      child: Container(
        height: 232,
        decoration: BoxDecoration(color: c.primaryLight, borderRadius: BorderRadius.circular(24)),
        child: Stack(
          children: [
            PositionedDirectional(
              top: 22,
              start: 20,
              child: Container(
                width: 160,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: card(),
                child: Row(children: [
                  IconTile(icon: Icons.menu_book_rounded, bg: c.successBg, fg: c.successText, size: 30, iconSize: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(space?.name.of(ar) ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
                      Text(f.nProjects(space == null ? 0 : app.projectsIn(space.id).length), style: TextStyle(fontSize: 11, color: c.text2)),
                    ]),
                  ),
                ]),
              ),
            ),
            PositionedDirectional(
              top: 44,
              end: 20,
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: card(),
                child: Row(children: [
                  Icon(Icons.check_circle_outline_rounded, size: 14, color: c.successText),
                  const SizedBox(width: 6),
                  Text(f.subsOf(done, total), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.successText)),
                ]),
              ),
            ),
            PositionedDirectional(top: 62, start: 38, child: Container(width: 1.5, height: 36, color: c.borderStrong)),
            PositionedDirectional(
              top: 90,
              start: 52,
              end: 44,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: card(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(project?.name.of(ar) ?? '',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
                    ),
                    Text('${(pct * 100).round()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.primaryText)),
                  ]),
                  const SizedBox(height: 9),
                  FbProgressBar(value: pct),
                ]),
              ),
            ),
            PositionedDirectional(top: 146, start: 70, child: Container(width: 1.5, height: 20, color: c.borderStrong)),
            PositionedDirectional(
              top: 154,
              start: 86,
              end: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: card(),
                child: Column(children: [
                  _miniTask(c, task?.subtasks.isNotEmpty == true ? task!.subtasks.first.title.of(ar) : '', true),
                  _miniTask(c, task?.title.of(ar) ?? '', false),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniTask(FbColors c, String title, bool done) => SizedBox(
        height: 30,
        child: Row(children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: done ? c.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: done ? c.primary : c.borderStrong, width: 1.6),
            ),
            child: done ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: done ? FontWeight.w400 : FontWeight.w600,
                  color: done ? c.text2 : c.text,
                  decoration: done ? TextDecoration.lineThrough : null,
                )),
          ),
        ]),
      );
}
