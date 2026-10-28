import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../navigation.dart';
import '../widgets/cards.dart';
import '../widgets/controls.dart';
import '../widgets/layout.dart';
import 'search_screen.dart';
import 'space_form_screen.dart';

class SpacesScreen extends StatelessWidget {
  const SpacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    void create() => push(context, const SpaceFormScreen());

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        PageHeader(
          title: t['projects'],
          subtitle: t['projectsSub'],
          actions: [
            FbIconButton(icon: Icons.search_rounded, label: t['search'], bordered: true, onTap: () => push(context, const SearchScreen())),
            FbIconButton(icon: Icons.add_rounded, label: t['createSpace'], background: c.primary, foreground: Colors.white, onTap: create),
          ],
        ),
        // Active projects (moved here from the home screen)
        if (app.activeProjects.isNotEmpty) ...[
          const SizedBox(height: 20),
          SectionHeader(title: t['activeProjects'], count: app.activeProjects.length, padding: const EdgeInsets.symmetric(horizontal: Sp.page)),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Sp.page),
              itemCount: app.activeProjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => Align(alignment: Alignment.topCenter, child: ProjectCard(project: app.activeProjects[i])),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SectionHeader(title: t['spaces'], padding: const EdgeInsets.symmetric(horizontal: Sp.page)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.page),
          child: app.spaces.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: EmptyState(
                    icon: Icons.grid_view_rounded,
                    bordered: false,
                    large: true,
                    title: t['noSpaces'],
                    message: t['noSpacesSub'],
                    actionLabel: t['createSpace'],
                    onAction: create,
                  ),
                )
              : TwoColumnGrid(
                  children: [
                    for (final s in app.spaces) SpaceCard(space: s),
                    FbCard(
                      onTap: create,
                      color: Colors.transparent,
                      borderColor: c.borderStrong,
                      borderWidth: 1.2,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 132),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconTile(icon: Icons.add_rounded, bg: c.surface2, fg: c.text, size: 44, iconSize: 22),
                            const SizedBox(height: 10),
                            Text(t['newSpace'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text2)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
