import 'package:flutter/material.dart';

import '../core/context_ext.dart';

/// Compact bottom navigation: Home · Tasks · (+) · Calendar · Spaces.
class FbBottomNav extends StatelessWidget {
  const FbBottomNav({super.key, required this.index, required this.onTap, required this.onCreate});
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final t = context.s;
    Widget item(int i, IconData icon, IconData activeIcon, String label) {
      final selected = i == index;
      final color = selected ? c.primary : c.text2;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: InkResponse(
            onTap: () => onTap(i),
            radius: 32,
            child: SizedBox(
              height: 60,
              child: ExcludeSemantics(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(selected ? activeIcon : icon, key: ValueKey(selected), size: 24, color: color),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: color,
                        fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                        fontFamilyFallback: DefaultTextStyle.of(context).style.fontFamilyFallback,
                      ),
                      child: Text(label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: c.navBg, border: Border(top: BorderSide(color: c.border))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              item(0, Icons.home_outlined, Icons.home_rounded, t['home']),
              item(1, Icons.checklist_rounded, Icons.checklist_rounded, t['tasks']),
              Expanded(
                child: Center(
                  child: Semantics(
                    button: true,
                    label: t['create'],
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: [BoxShadow(color: c.primary.withAlpha(80), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Material(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(17),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(17),
                          onTap: onCreate,
                          child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              item(2, Icons.calendar_month_outlined, Icons.calendar_month_rounded, t['calendar']),
              item(3, Icons.grid_view_outlined, Icons.grid_view_rounded, t['spaces']),
            ],
          ),
        ),
      ),
    );
  }
}
