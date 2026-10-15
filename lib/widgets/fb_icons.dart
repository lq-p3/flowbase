import 'package:flutter/material.dart';

/// Outline icon set used for Spaces and Projects (Material Symbols, rounded/outlined).
class FbIcons {
  static const Map<String, IconData> map = {
    'briefcase': Icons.work_outline_rounded,
    'book': Icons.menu_book_rounded,
    'user': Icons.person_outline_rounded,
    'activity': Icons.monitor_heart_outlined,
    'home': Icons.home_outlined,
    'code': Icons.code_rounded,
    'target': Icons.track_changes_rounded,
    'star': Icons.star_outline_rounded,
    'folder': Icons.folder_outlined,
    'phone': Icons.smartphone_rounded,
    'monitor': Icons.desktop_windows_outlined,
    'note': Icons.description_outlined,
  };

  static const spaceChoices = ['briefcase', 'book', 'user', 'activity', 'home', 'code', 'target', 'star'];
  static const projectChoices = ['folder', 'phone', 'monitor', 'target', 'book', 'star', 'home', 'code'];

  static IconData of(String? name) => map[name] ?? Icons.folder_outlined;
}

/// An icon that mirrors itself in right-to-left layouts (chevrons, arrows).
class DirIcon extends StatelessWidget {
  const DirIcon(this.icon, {super.key, this.size = 22, this.color});
  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final w = Icon(icon, size: size, color: color);
    // Some Material icons already mirror themselves; only flip the ones that don't.
    return rtl && !icon.matchTextDirection ? Transform.flip(flipX: true, child: w) : w;
  }
}
