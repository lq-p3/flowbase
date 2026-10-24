import 'package:flutter/material.dart';

import '../core/context_ext.dart';
import '../core/tokens.dart';
import '../navigation.dart';
import '../widgets/controls.dart';
import '../widgets/overlays.dart';
import 'main_shell.dart';

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Opens the app after a successful sign-in or sign-up.
void _enterApp(BuildContext context) {
  context.appRead.setTab(0);
  Navigator.of(context).pushAndRemoveUntil(fbRoute(const MainShell()), (_) => false);
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _show = false;
  bool _tried = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  bool get _emailOk => _emailRe.hasMatch(_email.text.trim());

  Future<void> _submit() async {
    if (_busy) return;
    if (!_emailOk || _pw.text.isEmpty) {
      setState(() => _tried = true);
      return;
    }
    setState(() => _busy = true);
    final error = await context.appRead.signIn(_email.text.trim(), _pw.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      showToast(error, icon: Icons.error_outline_rounded);
      return;
    }
    _enterApp(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final t = context.s;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: FbIconButton(
                          icon: Icons.chevron_left_rounded,
                          iconSize: 28,
                          directional: true,
                          label: t['back'],
                          onTap: () => Navigator.maybePop(context),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Sp.page, 12, Sp.page, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(t['welcomeBack'], style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: c.text)),
                          const SizedBox(height: 8),
                          Text(t['signInSub'], style: TextStyle(fontSize: 15, color: c.text2)),
                          const SizedBox(height: 32),
                          FbTextField(
                            controller: _email,
                            label: t['email'],
                            hint: 'name@example.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            error: _tried && !_emailOk ? t['errEmail'] : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 18),
                          FbTextField(
                            controller: _pw,
                            label: t['password'],
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscure: !_show,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _submit(),
                            error: _tried && _pw.text.isEmpty ? t['errPwEmpty'] : null,
                            onChanged: (_) => setState(() {}),
                            suffix: IconButton(
                              tooltip: _show ? t['hidePw'] : t['showPw'],
                              icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: c.text2),
                              onPressed: () => setState(() => _show = !_show),
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: FbTextButton(label: t['forgot'], onTap: () => showToast(t['comingSoon'], icon: Icons.info_outline_rounded)),
                          ),
                          const SizedBox(height: 6),
                          PrimaryButton(label: _busy ? t['loading'] : t['signIn'], onPressed: _busy ? null : _submit),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _FooterLink(
                      text: t['noAccount'],
                      action: t['createAccount'],
                      onTap: () => replace(context, const SignUpScreen()),
                    ),
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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _show = false;
  bool _submitted = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _nameOk => _name.text.trim().length >= 2;
  bool get _emailOk => _emailRe.hasMatch(_email.text.trim());
  bool get _pwOk => _pw.text.length >= 8;
  bool get _matchOk => _pw2.text.isNotEmpty && _pw2.text == _pw.text;

  /// Validation appears once a field has content, or after the first submit.
  bool _shown(TextEditingController c) => _submitted || c.text.isNotEmpty;

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_nameOk && _emailOk && _pwOk && _matchOk)) {
      setState(() => _submitted = true);
      return;
    }
    setState(() => _busy = true);
    final (error, needsConfirm) = await context.appRead.signUp(_name.text.trim(), _email.text.trim(), _pw.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      showToast(error, icon: Icons.error_outline_rounded);
    } else if (needsConfirm) {
      showToast(context.s['confirmEmailSent'], icon: Icons.mail_outline_rounded);
      replace(context, const SignInScreen());
    } else {
      _enterApp(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final t = context.s;
    Widget eye() => IconButton(
          tooltip: _show ? t['hidePw'] : t['showPw'],
          icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: c.text2),
          onPressed: () => setState(() => _show = !_show),
        );
    Widget? status(bool shown, bool ok) => !shown
        ? null
        : Icon(ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded, size: 20, color: ok ? c.successText : c.dangerText);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: FbIconButton(
                  icon: Icons.chevron_left_rounded,
                  iconSize: 28,
                  directional: true,
                  label: t['back'],
                  onTap: () => Navigator.maybePop(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.page, 8, Sp.page, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t['signupTitle'], style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: c.text)),
                  const SizedBox(height: 8),
                  Text(t['signupSub'], style: TextStyle(fontSize: 15, height: 1.45, color: c.text2)),
                  const SizedBox(height: 26),
                  FbTextField(
                    controller: _name,
                    label: t['fullName'],
                    hint: t['user'],
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    error: _shown(_name) && !_nameOk ? t['errName'] : null,
                    success: _shown(_name) && _nameOk ? '' : null,
                    suffix: status(_shown(_name), _nameOk),
                  ),
                  const SizedBox(height: 16),
                  FbTextField(
                    controller: _email,
                    label: t['email'],
                    hint: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    error: _shown(_email) && !_emailOk ? t['errEmail'] : null,
                    success: _shown(_email) && _emailOk ? '' : null,
                    suffix: status(_shown(_email), _emailOk),
                  ),
                  const SizedBox(height: 16),
                  FbTextField(
                    controller: _pw,
                    label: t['password'],
                    hint: '••••••••',
                    obscure: !_show,
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (_) => setState(() {}),
                    helper: t['pwHint'],
                    error: _shown(_pw) && !_pwOk ? t['errPw'] : null,
                    success: _shown(_pw) && _pwOk ? t['okPw'] : null,
                    suffix: eye(),
                  ),
                  const SizedBox(height: 16),
                  FbTextField(
                    controller: _pw2,
                    label: t['confirmPw'],
                    hint: '••••••••',
                    obscure: !_show,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                    error: _shown(_pw2) && !_matchOk ? t['errMatch'] : null,
                    success: _shown(_pw2) && _matchOk ? t['okMatch'] : null,
                    suffix: eye(),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(label: _busy ? t['loading'] : t['createAccountBtn'], onPressed: _busy ? null : _submit),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            _FooterLink(text: t['haveAccount'], action: t['signIn'], onTap: () => replace(context, const SignInScreen())),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.text, required this.action, required this.onTap});
  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(text, style: TextStyle(fontSize: 14, color: context.fb.text2)),
          FbTextButton(label: action, onTap: onTap),
        ],
      ),
    );
  }
}
