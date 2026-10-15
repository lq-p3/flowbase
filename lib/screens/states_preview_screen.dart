import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../navigation.dart';
import '../widgets/layout.dart';
import '../widgets/overlays.dart';

/// Debug-only gallery of loading / empty / error states, dialogs and toasts
/// (reachable from Settings › Other while running in debug mode).
class StatesPreviewScreen extends StatelessWidget {
  const StatesPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final t = context.s;

    void preview(String title, Widget child) => push(
          context,
          Scaffold(body: SafeArea(child: Column(children: [DetailHeader(title: title), Expanded(child: child)]))),
        );

    Widget emptyPage(Widget child) => ListView(padding: const EdgeInsets.all(Sp.page), children: [const SizedBox(height: 40), child]);

    final items = <(IconData, String, VoidCallback)>[
      (Icons.hourglass_empty_rounded, t['skelHome'], () => preview(t['skelHome'], const HomeSkeleton())),
      (Icons.hourglass_empty_rounded, t['skelList'], () => preview(t['skelList'], const ListSkeleton())),
      (Icons.hourglass_empty_rounded, t['skelGrid'], () => preview(t['skelGrid'], const GridSkeleton())),
      (
        Icons.check_circle_outline_rounded,
        t['caughtUp'],
        () => preview(
              t['todaysTasks'],
              emptyPage(EmptyState(icon: Icons.check_circle_outline_rounded, iconBg: c.successBg, iconFg: c.successText, title: t['caughtUp'], message: t['caughtUpSub'])),
            )
      ),
      (
        Icons.grid_view_rounded,
        t['noSpaces'],
        () => preview(
              t['spaces'],
              emptyPage(EmptyState(
                  icon: Icons.grid_view_rounded, large: true, bordered: false, title: t['noSpaces'], message: t['noSpacesSub'], actionLabel: t['createSpace'], onAction: () {})),
            )
      ),
      (
        Icons.folder_outlined,
        t['noProjects'],
        () => preview(
              t['projects'],
              emptyPage(EmptyState(icon: Icons.folder_outlined, title: t['noProjects'], message: t['noProjectsSub'], actionLabel: t['createProject'], onAction: () {})),
            )
      ),
      (
        Icons.search_off_rounded,
        t['noResults'],
        () => preview(
              t['searchTitle'],
              emptyPage(EmptyState(icon: Icons.search_off_rounded, bordered: false, iconBg: c.surface2, iconFg: c.text2, title: t['noResults'], message: t['noResultsSub'])),
            )
      ),
      (Icons.error_outline_rounded, t['errGeneric'], () => preview(t['errGeneric'], ErrorView(kind: ErrorKind.generic, onRetry: () => Navigator.pop(context)))),
      (Icons.inbox_outlined, t['errTasks'], () => preview(t['errTasks'], ErrorView(kind: ErrorKind.tasks, onRetry: () => Navigator.pop(context)))),
      (Icons.wifi_off_rounded, t['errOffline'], () => preview(t['errOffline'], ErrorView(kind: ErrorKind.offline, onRetry: () => Navigator.pop(context)))),
      (Icons.delete_outline_rounded, t['showDialog'], () => showConfirm(context, title: t['dTaskT'], message: t['dTaskM'])),
      (Icons.notifications_none_rounded, t['showToast'], () => showToast(t['taskCreated'])),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DetailHeader(title: t['statesPreview']),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 28),
                children: [
                  Text(t['statesSub'], style: TextStyle(fontSize: 14, color: c.text2)),
                  const SizedBox(height: 14),
                  GroupCard(children: [for (final i in items) ListRow(icon: i.$1, label: i.$2, onTap: i.$3)]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
