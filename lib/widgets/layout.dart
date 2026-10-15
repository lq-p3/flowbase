import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import 'controls.dart';
import 'fb_icons.dart';

/// Title row used on top-level tabs (Home has its own greeting header).
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.page, Sp.md, Sp.page, 0),
      child: Row(
        crossAxisAlignment: subtitle == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: FbText.pageTitle(c.text))),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: TextStyle(fontSize: 14, color: c.text2)),
                ],
              ],
            ),
          ),
          for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: 8), actions[i]],
        ],
      ),
    );
  }
}

/// Back / title / trailing header for drill-down screens.
class DetailHeader extends StatelessWidget {
  const DetailHeader({super.key, required this.title, this.trailing, this.close = false, this.onBack});
  final String title;
  final Widget? trailing;
  final bool close;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            FbIconButton(
              icon: close ? Icons.close_rounded : Icons.chevron_left_rounded,
              iconSize: close ? 23 : 28,
              directional: !close,
              label: close ? context.s['close'] : context.s['back'],
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FbText.headerTitle(c.text)),
              ),
            ),
            trailing ?? const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.count, this.action, this.onAction, this.padding = EdgeInsets.zero});
  final String title;
  final int? count;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Flexible(child: Semantics(header: true, child: Text(title, style: FbText.section(c.text)))),
            if (count != null) ...[const SizedBox(width: 8), CountPill(count: count!, accent: true)],
            const Spacer(),
            if (action != null && onAction != null) FbTextButton(label: action!, onTap: onAction!),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase label above grouped settings / search results.
class CapsLabel extends StatelessWidget {
  const CapsLabel(this.text, {super.key, this.color, this.trailing});
  final String text;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: FbText.caps(color ?? context.fb.text2))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Two equal columns that grow with their content (safer than a fixed-ratio GridView).
class TwoColumnGrid extends StatelessWidget {
  const TwoColumnGrid({super.key, required this.children, this.gap = 12});
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: gap));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: children[i]),
            SizedBox(width: gap),
            Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

/// Compact inline statistics (e.g. "3 Projects | 12 Active | 20 Completed").
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.items, this.center = true});
  final List<(String, String)> items;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return FbCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, thickness: 1, color: c.border),
              Expanded(
                child: Column(
                  crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    Text(items[i].$1, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.text)),
                    const SizedBox(height: 2),
                    Text(items[i].$2,
                        textAlign: center ? TextAlign.center : TextAlign.start,
                        style: TextStyle(fontSize: 12, color: c.text2, height: 1.25)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sticky bottom action area for forms and detail screens.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Container(
      decoration: BoxDecoration(color: c.bg, border: Border(top: BorderSide(color: c.border))),
      padding: const EdgeInsets.fromLTRB(Sp.page, 12, Sp.page, 12),
      child: SafeArea(top: false, child: child),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.bordered = true,
    this.iconBg,
    this.iconFg,
    this.large = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool bordered;
  final Color? iconBg;
  final Color? iconFg;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: large ? 40 : 30),
      decoration: bordered
          ? BoxDecoration(borderRadius: BorderRadius.circular(Rad.card), border: Border.all(color: c.borderStrong, width: 1.2))
          : null,
      child: Column(
        children: [
          IconTile(icon: icon, bg: iconBg ?? c.primaryLight, fg: iconFg ?? c.primaryText, size: large ? 64 : 48),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: large ? 18 : 16, fontWeight: large ? FontWeight.w700 : FontWeight.w600, color: c.text)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.45, color: c.text2)),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            PrimaryButton(label: actionLabel!, onPressed: onAction, icon: Icons.add_rounded, expand: false, height: 46),
          ],
        ],
      ),
    );
  }
}

enum ErrorKind { generic, tasks, offline }

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.kind, required this.onRetry});
  final ErrorKind kind;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final t = context.s;
    final (icon, bg, fg, title, msg) = switch (kind) {
      ErrorKind.generic => (Icons.error_outline_rounded, c.dangerBg, c.dangerText, t['errGeneric'], t['errGenericSub']),
      ErrorKind.tasks => (Icons.inbox_outlined, c.warningBg, c.warningText, t['errTasks'], t['errTasksSub']),
      ErrorKind.offline => (Icons.wifi_off_rounded, c.surface2, c.text2, t['errOffline'], t['errOfflineSub']),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(icon: icon, bg: bg, fg: fg, size: 68),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: c.text)),
              const SizedBox(height: 8),
              Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, height: 1.5, color: c.text2)),
              const SizedBox(height: 20),
              PrimaryButton(label: t['tryAgain'], onPressed: onRetry, icon: Icons.refresh_rounded, expand: false, height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Skeletons
// ============================================================

class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child});
  final Widget child;
  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) return widget.child;
    return FadeTransition(opacity: Tween(begin: 1.0, end: 0.5).animate(_c), child: widget.child);
  }
}

class Bone extends StatelessWidget {
  const Bone({super.key, this.width, required this.height, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: context.fb.skeleton, borderRadius: BorderRadius.circular(radius)),
      );
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.s['loading'],
      child: Pulse(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(Sp.page, 16, Sp.page, 24),
          children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Bone(width: 110, height: 12),
                  SizedBox(height: 8),
                  Bone(width: 210, height: 22),
                ]),
              ),
              const Bone(width: 44, height: 44, radius: 14),
              const SizedBox(width: 8),
              const Bone(width: 44, height: 44, radius: 22),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              for (var i = 0; i < 5; i++) ...[if (i > 0) const SizedBox(width: 8), const Expanded(child: Bone(height: 70, radius: 16))],
            ]),
            const SizedBox(height: 16),
            const Bone(height: 80, radius: 16),
            const SizedBox(height: 28),
            const Bone(width: 140, height: 18),
            const SizedBox(height: 14),
            const Row(children: [Expanded(child: Bone(height: 150, radius: 16)), SizedBox(width: 12), Expanded(child: Bone(height: 150, radius: 16))]),
            const SizedBox(height: 28),
            const Bone(width: 110, height: 18),
            const SizedBox(height: 14),
            const Row(children: [Expanded(child: Bone(height: 68, radius: 16)), SizedBox(width: 12), Expanded(child: Bone(height: 68, radius: 16))]),
          ],
        ),
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    Widget row() => Container(
          height: 78,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Bone(width: 22, height: 22, radius: 7),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                FractionallySizedBox(widthFactor: 0.8, child: Bone(height: 13, radius: 6)),
                SizedBox(height: 10),
                FractionallySizedBox(widthFactor: 0.5, child: Bone(height: 10, radius: 5)),
              ]),
            ),
            const Align(alignment: Alignment.bottomCenter, child: Bone(width: 58, height: 22)),
          ]),
        );
    return Semantics(
      label: context.s['loading'],
      child: Pulse(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(Sp.page, 16, Sp.page, 24),
          children: [
            const Align(alignment: AlignmentDirectional.centerStart, child: Bone(width: 170, height: 26)),
            const SizedBox(height: 16),
            const Bone(height: 48, radius: 14),
            const SizedBox(height: 12),
            const Bone(height: 46, radius: 14),
            const SizedBox(height: 20),
            for (var i = 0; i < 5; i++) row(),
          ],
        ),
      ),
    );
  }
}

class GridSkeleton extends StatelessWidget {
  const GridSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    Widget card() => Container(
          height: 164,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
            Bone(width: 44, height: 44, radius: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Bone(width: 90, height: 14, radius: 6),
              SizedBox(height: 8),
              Bone(width: 70, height: 10, radius: 5),
              SizedBox(height: 6),
              Bone(width: 80, height: 10, radius: 5),
            ]),
          ]),
        );
    return Semantics(
      label: context.s['loading'],
      child: Pulse(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(Sp.page, 16, Sp.page, 24),
          children: [
            const Align(alignment: AlignmentDirectional.centerStart, child: Bone(width: 120, height: 26)),
            const SizedBox(height: 10),
            const Align(alignment: AlignmentDirectional.centerStart, child: Bone(width: 230, height: 13)),
            const SizedBox(height: 22),
            TwoColumnGrid(children: [card(), card(), card(), card()]),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Settings rows
// ============================================================

class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Rad.card), border: Border.all(color: c.border)),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.label,
    this.icon,
    this.iconTile = false,
    this.value,
    this.onTap,
    this.trailing,
    this.chevron = true,
    this.valueDot,
  });

  final String label;
  final IconData? icon;
  final bool iconTile;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool chevron;
  final Color? valueDot;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 14, end: 12),
          child: Row(
            children: [
              if (icon != null) ...[
                iconTile
                    ? IconTile(icon: icon!, bg: c.surface2, fg: c.text, size: 34, iconSize: 18)
                    : Icon(icon, size: 19, color: c.text2),
                const SizedBox(width: 12),
              ],
              Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.text)),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (valueDot != null) ...[
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: valueDot, shape: BoxShape.circle)),
                      const SizedBox(width: 7),
                    ],
                    if (value != null)
                      Flexible(
                        child: Text(value!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 14, color: c.text2)),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null && chevron && onTap != null) ...[
                const SizedBox(width: 6),
                DirIcon(Icons.chevron_right_rounded, size: 20, color: c.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DragHandle extends StatelessWidget {
  const DragHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(top: 8, bottom: 10),
          decoration: BoxDecoration(color: context.fb.borderStrong, borderRadius: BorderRadius.circular(2)),
        ),
      );
}
