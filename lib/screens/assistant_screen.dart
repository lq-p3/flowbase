import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../widgets/controls.dart';
import '../widgets/layout.dart';

/// Chat with the AI secretary. It can read, add and update tasks for you.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, this.initialMessage});

  /// Sent right away when the screen opens (e.g. typed on the home screen).
  final String? initialMessage;
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _toBottom();
    final first = widget.initialMessage?.trim() ?? '';
    if (first.isNotEmpty) {
      _input.text = first;
      WidgetsBinding.instance.addPostFrameCallback((_) => _send());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _input.clear();
      _busy = true;
    });
    _toBottom();
    await context.appRead.askAssistant(text);
    if (!mounted) return;
    setState(() => _busy = false);
    _toBottom();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final c = context.fb;
    final t = context.s;
    final items = [(fromUser: false, text: t['assistantHi']), ...app.assistantChat];

    Widget bubble(({bool fromUser, String text}) m) => Align(
          alignment: m.fromUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: m.fromUser ? c.primary : c.surface,
              border: m.fromUser ? null : Border.all(color: c.border),
              borderRadius: BorderRadius.circular(Rad.card),
            ),
            child: _MessageText(
              m.text,
              style: TextStyle(fontSize: 15, height: 1.45, color: m.fromUser ? Colors.white : c.text),
              linkColor: m.fromUser ? Colors.white : c.primary,
            ),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DetailHeader(
              title: t['assistant'],
              trailing: app.assistantChat.isEmpty
                  ? null
                  : FbIconButton(icon: Icons.delete_sweep_outlined, label: t['assistantClear'], onTap: context.appRead.clearAssistant),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 8),
                children: [
                  for (final m in items) bubble(m),
                  if (_busy)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.primary)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 12),
              child: Row(
                children: [
                  Expanded(
                    child: FbTextField(
                      controller: _input,
                      hint: t['assistantPh'],
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FbIconButton(icon: Icons.send_rounded, label: t['assistantPh'], bordered: true, directional: true, onTap: _busy ? () {} : _send),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A chat message you can select and copy (long press), with web links you can tap.
class _MessageText extends StatefulWidget {
  const _MessageText(this.text, {required this.style, required this.linkColor});
  final String text;
  final TextStyle style;
  final Color linkColor;
  @override
  State<_MessageText> createState() => _MessageTextState();
}

class _MessageTextState extends State<_MessageText> {
  static final _link = RegExp(r'https?://[^\s]*[^\s.,!?؟،)]');
  final _taps = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _taps) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _taps) {
      r.dispose();
    }
    _taps.clear();
    final spans = <TextSpan>[];
    var start = 0;
    for (final m in _link.allMatches(widget.text)) {
      if (m.start > start) spans.add(TextSpan(text: widget.text.substring(start, m.start)));
      final url = m.group(0)!;
      final tap = TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      _taps.add(tap);
      spans.add(TextSpan(
        text: url,
        recognizer: tap,
        style: TextStyle(color: widget.linkColor, decoration: TextDecoration.underline, decorationColor: widget.linkColor),
      ));
      start = m.end;
    }
    if (start < widget.text.length) spans.add(TextSpan(text: widget.text.substring(start)));
    return SelectableText.rich(TextSpan(style: widget.style, children: spans));
  }
}
