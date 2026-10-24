import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../widgets/controls.dart';
import '../widgets/layout.dart';

/// Chat with the AI secretary. It can read, add and update tasks for you.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<({bool fromUser, String text})> _chat = [];
  bool _busy = false;

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
      _chat.add((fromUser: true, text: text));
      _input.clear();
      _busy = true;
    });
    _toBottom();
    final (reply, error) = await context.appRead.askAssistant(_chat);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _chat.add((fromUser: false, text: reply ?? '${context.s['assistantErr']}: $error'));
    });
    _toBottom();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final t = context.s;
    final items = [(fromUser: false, text: t['assistantHi']), ..._chat];

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
            child: Text(m.text, style: TextStyle(fontSize: 15, height: 1.45, color: m.fromUser ? Colors.white : c.text)),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DetailHeader(title: t['assistant']),
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
