import 'dart:async';

import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/layout.dart';
import '../navigation.dart';
import 'assistant_screen.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'spaces_screen.dart';
import 'tasks_screen.dart';

/// Top-level screens with the bottom navigation. Drill-down screens are pushed on top
/// (without the bottom bar) and use Back navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final Set<int> _visited = {};
  int? _loading;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _visit(context.appRead.tab);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// First visit to a tab shows its skeleton briefly — the way real data would load.
  void _visit(int i) {
    if (_visited.add(i)) {
      _loading = i;
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 550), () {
        if (mounted) setState(() => _loading = null);
      });
    }
  }

  void _select(int i) {
    setState(() => _visit(i));
    context.appRead.setTab(i);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final index = app.tab;
    if (!_visited.contains(index)) _visit(index); // tab changed from elsewhere (e.g. "View all tasks")

    Widget skeleton() => switch (index) { 0 => const HomeSkeleton(), 3 => const GridSkeleton(), _ => const ListSkeleton() };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _loading == index
              ? KeyedSubtree(key: ValueKey('skeleton$index'), child: skeleton())
              : IndexedStack(
                  key: const ValueKey('tabs'),
                  index: index,
                  children: const [HomeScreen(), TasksScreen(), CalendarScreen(), SpacesScreen()],
                ),
        ),
      ),
      bottomNavigationBar: FbBottomNav(index: index, onTap: _select, onSecretary: () => push(context, const AssistantScreen())),
    );
  }
}
