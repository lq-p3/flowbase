import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../data/models.dart';

const _fast = Duration(milliseconds: 180);

// ============================================================
// Surfaces
// ============================================================

/// White card with a hairline border. Tappable when [onTap] is set,
/// with a subtle press-scale micro-interaction.
class FbCard extends StatefulWidget {
  const FbCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.radius = Rad.card,
    this.borderWidth = 1,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final double borderWidth;

  @override
  State<FbCard> createState() => _FbCardState();
}

class _FbCardState extends State<FbCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final br = BorderRadius.circular(widget.radius);
    final body = Ink(
      decoration: BoxDecoration(
        color: widget.color ?? c.surface,
        borderRadius: br,
        border: Border.all(color: widget.borderColor ?? c.border, width: widget.borderWidth),
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );
    if (widget.onTap == null) {
      return Material(type: MaterialType.transparency, child: body);
    }
    return AnimatedScale(
      scale: _down ? 0.98 : 1,
      duration: const Duration(milliseconds: 150),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: br,
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _down = v),
          child: body,
        ),
      ),
    );
  }
}

// ============================================================
// Buttons
// ============================================================

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
    this.height = 52,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: danger ? c.dangerSolid : c.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.borderStrong,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.button)),
        ),
        child: _ButtonContent(label: label, icon: icon, color: Colors.white),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
    this.height = 52,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final fg = danger ? c.dangerText : c.text;
    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: danger ? Colors.transparent : c.surface,
          foregroundColor: fg,
          side: BorderSide(color: danger ? c.danger : c.border, width: danger ? 1.5 : 1),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.button)),
        ),
        child: _ButtonContent(label: label, icon: icon, color: fg, size: 15),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, required this.icon, required this.color, this.size = 16});
  final String label;
  final IconData? icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 19, color: color), const SizedBox(width: 8)],
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: color)),
        ),
      ],
    );
  }
}

/// Small text-only action ("See all", "Forgot password?").
class FbTextButton extends StatelessWidget {
  const FbTextButton({super.key, required this.label, required this.onTap, this.color, this.size = 14});
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        foregroundColor: color ?? context.fb.primaryText,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: color ?? context.fb.primaryText)),
    );
  }
}

/// 44×44 icon button. [bordered] draws the white card style used in page headers.
class FbIconButton extends StatelessWidget {
  const FbIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.bordered = false,
    this.background,
    this.foreground,
    this.borderColor,
    this.size = 44,
    this.iconSize = 21,
    this.badge,
    this.directional = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool bordered;
  final Color? background;
  final Color? foreground;
  final Color? borderColor;
  final double size;
  final double iconSize;
  final String? badge;
  final bool directional;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final fg = foreground ?? c.text;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget ic = Icon(icon, size: iconSize, color: fg);
    if (directional && rtl && !icon.matchTextDirection) ic = Transform.flip(flipX: true, child: ic);
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: background ?? (bordered ? c.surface : Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: bordered || borderColor != null ? BorderSide(color: borderColor ?? c.border) : BorderSide.none,
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  ExcludeSemantics(child: ic),
                  if (badge != null)
                    PositionedDirectional(
                      top: -5,
                      end: -5,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: c.bg, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(badge!,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, height: 1)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Inputs
// ============================================================

class FbTextField extends StatelessWidget {
  const FbTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.error,
    this.success,
    this.helper,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.textInputAction,
    this.autofillHints,
    this.focusBorder = true,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? error;
  final String? success;
  final String? helper;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool focusBorder;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final hasError = error != null;
    final hasSuccess = !hasError && success != null;
    final borderColor = hasError ? c.danger : hasSuccess ? c.success : c.border;
    OutlineInputBorder border(Color col, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Rad.input),
          borderSide: BorderSide(color: col, width: w),
        );
    final msg = error ?? success ?? helper;
    final msgColor = hasError ? c.dangerText : hasSuccess ? c.successText : c.text2;
    final msgIcon = hasError ? Icons.error_outline_rounded : hasSuccess ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: FbText.label(c.text)),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLines: obscure ? 1 : maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofocus: autofocus,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          cursorColor: c.primary,
          style: TextStyle(fontSize: 15.5, color: c.text, height: 1.4),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 15.5, color: c.muted),
            filled: true,
            fillColor: c.surface,
            isDense: true,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20, color: c.muted),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            enabledBorder: border(borderColor, hasError || hasSuccess ? 1.5 : 1),
            focusedBorder: border(hasError ? c.danger : (focusBorder ? c.primary : borderColor), 1.6),
            border: border(borderColor, 1),
          ),
        ),
        if (msg != null && msg.isNotEmpty) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(msgIcon, size: 15, color: msgColor),
              const SizedBox(width: 6),
              Expanded(child: Text(msg, style: TextStyle(fontSize: 13, color: msgColor))),
            ],
          ),
        ],
      ],
    );
  }
}

/// Rounded search field with clear button.
class FbSearchField extends StatelessWidget {
  const FbSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.autofocus = false,
    this.highlight = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      cursorColor: c.primary,
      style: TextStyle(fontSize: 15.5, color: c.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 15.5, color: c.muted),
        filled: true,
        fillColor: c.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: Icon(Icons.search_rounded, size: 21, color: highlight ? c.primaryText : c.muted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.s['clearSearch'],
                icon: Icon(Icons.close_rounded, size: 19, color: c.text2),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Rad.input),
          borderSide: BorderSide(color: highlight ? c.primary : c.border, width: highlight ? 1.5 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Rad.input),
          borderSide: BorderSide(color: c.primary, width: 1.6),
        ),
      ),
    );
  }
}

/// Selectable chip. Shows a check when selected so selection never relies on color alone.
class FbChip extends StatelessWidget {
  const FbChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.showCheck = true,
    this.selectedBg,
    this.selectedFg,
    this.selectedBorder,
    this.height = 40,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool showCheck;
  final Color? selectedBg;
  final Color? selectedFg;
  final Color? selectedBorder;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final bg = selected ? (selectedBg ?? c.primaryLight) : c.surface;
    final fg = selected ? (selectedFg ?? c.primaryText) : c.text;
    final bd = selected ? (selectedBorder ?? c.primary) : c.border;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Rad.chip),
          child: AnimatedContainer(
            duration: _fast,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(Rad.chip),
              border: Border.all(color: bd, width: 1.5),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: expand ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                if (selected && showCheck) ...[Icon(Icons.check_rounded, size: 15, color: fg), const SizedBox(width: 5)],
                if (icon != null) ...[Icon(icon, size: 17, color: fg), const SizedBox(width: 7)],
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fg)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented tab bar (All / Today / Upcoming / Completed).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: i == index,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? c.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                        color: i == index ? Colors.white : c.text2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Task checkbox with a 44×44 touch target and an animated check.
class FbCheckbox extends StatelessWidget {
  const FbCheckbox({
    super.key,
    required this.checked,
    required this.onTap,
    required this.semanticLabel,
    this.inProgress = false,
    this.size = 22,
    this.color,
  });

  final bool checked;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool inProgress;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final col = color ?? c.primary;
    return Semantics(
      checked: checked,
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: _fast,
              curve: Curves.easeOut,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: checked ? col : Colors.transparent,
                borderRadius: BorderRadius.circular(size * 0.32),
                border: Border.all(color: checked || inProgress ? col : c.borderStrong, width: 1.8),
              ),
              child: AnimatedSwitcher(
                duration: _fast,
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: checked
                    ? Icon(Icons.check_rounded, key: const ValueKey('c'), size: size * 0.7, color: Colors.white)
                    : inProgress
                        ? Container(
                            key: const ValueKey('p'),
                            width: size * 0.36,
                            height: size * 0.36,
                            decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(3)),
                          )
                        : const SizedBox.shrink(key: ValueKey('e')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FbSwitch extends StatelessWidget {
  const FbSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: c.primary,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: c.borderStrong,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}

// ============================================================
// Progress & badges
// ============================================================

class FbProgressBar extends StatelessWidget {
  const FbProgressBar({super.key, required this.value, this.height = 4, this.color});
  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: c.surface2,
        alignment: AlignmentDirectional.centerStart,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (_, v, __) => FractionallySizedBox(
            widthFactor: v,
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(color: color ?? c.primary, borderRadius: BorderRadius.circular(height / 2)),
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 52, this.label});
  final double value;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        builder: (_, v, __) => Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: v,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              backgroundColor: c.primaryLight,
              color: c.primary,
            ),
            Center(
              child: Text(label ?? '${(v * 100).round()}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text)),
            ),
          ],
        ),
      ),
    );
  }
}

(Color, Color) priorityColors(FbColors c, Priority p) {
  switch (p) {
    case Priority.low:
      return (c.neutralBg, c.neutralText);
    case Priority.medium:
      return (c.warningBg, c.warningText);
    case Priority.high:
      return (c.dangerBg, c.dangerText);
    case Priority.urgent:
      return (c.dangerSolid, Colors.white);
  }
}

/// Priority = color + flag icon + text (never color alone).
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority, this.large = false});
  final Priority priority;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = priorityColors(context.fb, priority);
    return Container(
      height: large ? 32 : 22,
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(large ? 10 : 7)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: large ? 15 : 12, color: fg),
          SizedBox(width: large ? 6 : 4),
          Text(context.s[priority.name],
              style: TextStyle(fontSize: large ? 13 : 11.5, fontWeight: FontWeight.w600, color: fg, height: 1.1)),
        ],
      ),
    );
  }
}

(Color, Color, String) statusStyle(BuildContext context, TaskStatus s) {
  final c = context.fb;
  final t = context.s;
  switch (s) {
    case TaskStatus.todo:
      return (c.neutralBg, c.neutralText, t['todo']);
    case TaskStatus.inProgress:
      return (c.primaryLight, c.primaryText, t['inProgress']);
    case TaskStatus.done:
      return (c.successBg, c.successText, t['done']);
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.onTap});
  final TaskStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = statusStyle(context, status);
    final child = AnimatedContainer(
      duration: _fast,
      height: 32,
      padding: const EdgeInsetsDirectional.only(start: 12, end: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
          if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.expand_more_rounded, size: 17, color: fg)],
        ],
      ),
    );
    if (onTap == null) return child;
    return Semantics(
      button: true,
      label: '${context.s['changeStatus']}: $label',
      child: GestureDetector(onTap: onTap, child: ExcludeSemantics(child: child)),
    );
  }
}

class CountPill extends StatelessWidget {
  const CountPill({super.key, required this.count, this.accent = false});
  final int count;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: accent ? c.primaryLight : c.surface2, borderRadius: BorderRadius.circular(11)),
      child: Text('$count',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent ? c.primaryText : c.text2, height: 1)),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.bg, required this.fg, this.size = 40, this.iconSize});
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _fast,
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, size: iconSize ?? size * 0.5, color: fg),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.size = 44, this.filled = false});
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final app = context.app;
    final name = app.userName.isEmpty ? app.email : app.userName;
    final initials = name.isEmpty ? '' : name.split(RegExp(r'\s+')).take(2).map((w) => w.characters.first.toUpperCase()).join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: filled ? c.primary : c.primaryLight, shape: BoxShape.circle),
      child: Text(initials,
          style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w700, color: filled ? Colors.white : c.primaryText)),
    );
  }
}

/// FlowBase brand mark: three bars indented like Space → Project → Task.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 32, this.withWordmark = true});
  final double size;
  final bool withWordmark;

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    Widget bar(double widthFactor, double opacity) => Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: Container(
              height: size * 0.125,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((opacity * 255).round()),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
    // The mark is a logo: it never mirrors in RTL.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: size,
              height: size,
              padding: EdgeInsets.symmetric(horizontal: size * 0.22),
              decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(size * 0.31)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  bar(1, 1),
                  SizedBox(height: size * 0.09),
                  bar(0.72, 0.8),
                  SizedBox(height: size * 0.09),
                  bar(0.44, 0.6),
                ],
              ),
            ),
          ),
          if (withWordmark) ...[
            SizedBox(width: size * 0.31),
            Text('FlowBase',
                style: TextStyle(fontSize: size * 0.6, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: c.text)),
          ],
        ],
      ),
    );
  }
}
