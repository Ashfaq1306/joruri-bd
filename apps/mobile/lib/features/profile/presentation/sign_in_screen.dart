import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/firebase/email_link_auth.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/firebase/google_auth.dart';
import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/features/profile/presentation/profile_sync_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Sign in with Google, or with a link sent by e-mail (both free on the
/// Firebase Spark plan). After signing in, the profile saved on the phone is
/// put online. Returns true when signed in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  String? _error;
  String? _sentTo;
  // Sign in by itself only once, and only with the address saved when the link was sent.
  late bool _autoTried = ref.read(emailLinkAuthProvider).pendingEmail == null;
  late final _email = TextEditingController(text: ref.read(emailLinkAuthProvider).pendingEmail ?? '');
  final _pasted = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pasted.dispose();
    super.dispose();
  }

  void _start() => setState(() {
        _busy = true;
        _error = null;
      });

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  Future<void> _done() async {
    // Put the saved profile online now; the status shows on the profile card.
    await ref.read(profileSyncStatusProvider.notifier).sync();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/');
    }
  }

  Future<void> _signInGoogle() async {
    _start();
    final result = await ref.read(googleAuthProvider).signIn();
    if (!mounted) return;
    switch (result) {
      case SignInResult.signedIn:
        await _done();
      case SignInResult.cancelled:
        setState(() => _busy = false);
      case SignInResult.unavailable:
        _fail(context.s.signInNotAvailable);
      case SignInResult.failed:
        _fail(context.s.signInFailed);
    }
  }

  String _message(EmailLinkResult r) {
    final s = context.s;
    switch (r) {
      case EmailLinkResult.invalidEmail:
        return s.emailInvalid;
      case EmailLinkResult.emailMismatch:
        return s.signInEmailMismatch;
      case EmailLinkResult.linkInvalid:
        return s.signInLinkInvalid;
      case EmailLinkResult.tooMany:
        return s.tooManyTries;
      case EmailLinkResult.dailyLimit:
        return s.emailDailyLimit;
      case EmailLinkResult.unavailable:
        return s.signInNotAvailable;
      case EmailLinkResult.sent:
      case EmailLinkResult.signedIn:
      case EmailLinkResult.failed:
        return s.signInFailed;
    }
  }

  Future<void> _sendLink() async {
    FocusScope.of(context).unfocus();
    _start();
    final r = await ref.read(emailLinkAuthProvider).sendLink(_email.text, languageCode: context.s.languageCode);
    if (!mounted) return;
    if (r == EmailLinkResult.sent) {
      setState(() {
        _busy = false;
        _sentTo = _email.text.trim();
      });
    } else {
      _fail(_message(r));
    }
  }

  Future<void> _finish(String link) async {
    FocusScope.of(context).unfocus();
    _autoTried = true;
    _start();
    final r = await ref.read(emailLinkAuthProvider).complete(link, _email.text);
    if (!mounted) return;
    if (r == EmailLinkResult.signedIn) {
      ref.read(pendingSignInLinkProvider.notifier).state = null;
      await _done();
    } else {
      if (r == EmailLinkResult.linkInvalid) ref.read(pendingSignInLinkProvider.notifier).state = null;
      _fail(_message(r));
    }
  }

  Future<void> _usePasted() async {
    final link = _pasted.text.trim();
    final ok = await ref.read(emailLinkAuthProvider).isSignInLink(link);
    if (!mounted) return;
    if (!ok) {
      _fail(context.s.signInLinkInvalid);
      return;
    }
    ref.read(pendingSignInLinkProvider.notifier).state = link;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final ready = ref.watch(firebaseReadyProvider);
    final user = ref.watch(authUserProvider).valueOrNull;
    final link = ref.watch(pendingSignInLinkProvider);

    // Opened from the e-mail on the phone the link was asked on: sign in at once.
    if (link != null && user == null && !_autoTried && !_busy && EmailLinkAuth.looksLikeEmail(_email.text)) {
      _autoTried = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish(link));
    }

    final error = _error == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: JSpace.sm),
            child: Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
          );
    Widget spinnerOr(IconData icon) => _busy
        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : Icon(icon);
    final emailField = TextField(
      controller: _email,
      enabled: !_busy,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      decoration: InputDecoration(labelText: s.emailLabel, hintText: 'name@gmail.com', prefixIcon: const Icon(Icons.email_outlined)),
    );

    Widget body;
    if (ready.isLoading) {
      body = const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    } else if (ready.valueOrNull != true) {
      body = Text(s.onlineNotReady, style: theme.textTheme.titleMedium);
    } else if (user != null) {
      body = Text(s.signedInAs(user.email ?? user.displayName ?? ''), style: theme.textTheme.titleMedium);
    } else if (link != null) {
      // A sign-in link arrived: only the e-mail address is missing (or being checked).
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.finishSignIn, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: JSpace.sm),
          Text(s.finishSignInBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: JSpace.md),
          emailField,
          const SizedBox(height: JSpace.md),
          FilledButton.icon(onPressed: _busy ? null : () => _finish(link), icon: spinnerOr(Icons.login), label: Text(s.finishSignIn)),
          error,
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.signInBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: JSpace.sm),
          Text(s.phoneSelfDeclared, style: theme.textTheme.bodySmall),
          const SizedBox(height: JSpace.lg),
          FilledButton.icon(
            onPressed: _busy ? null : _signInGoogle,
            icon: spinnerOr(Icons.account_circle_outlined),
            label: Text(s.signInWithGoogle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: JSpace.md),
            child: Row(children: [
              const Expanded(child: Divider()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(s.orWord)),
              const Expanded(child: Divider()),
            ]),
          ),
          Text(s.signInWithEmail, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: JSpace.sm),
          emailField,
          const SizedBox(height: JSpace.sm),
          OutlinedButton.icon(
            onPressed: _busy ? null : _sendLink,
            icon: spinnerOr(Icons.send_outlined),
            label: Text(_sentTo == null ? s.sendSignInLink : s.sendAgain),
          ),
          error,
          if (_sentTo != null) ...[
            const SizedBox(height: JSpace.md),
            Container(
              padding: const EdgeInsets.all(JSpace.md),
              decoration: BoxDecoration(
                color: JColors.ok.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(JSize.radius),
              ),
              child: Text(s.signInLinkSent(_sentTo!), style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: JSpace.md),
            Text(s.pasteSignInLink, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            TextField(
              controller: _pasted,
              enabled: !_busy,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: s.signInLinkLabel,
                suffixIcon: IconButton(
                  tooltip: s.pasteWord,
                  icon: const Icon(Icons.content_paste),
                  onPressed: () async {
                    final clip = await Clipboard.getData(Clipboard.kTextPlain);
                    if (clip?.text != null) _pasted.text = clip!.text!;
                  },
                ),
              ),
            ),
            const SizedBox(height: JSpace.sm),
            TextButton(onPressed: _busy ? null : _usePasted, child: Text(s.finishSignIn)),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: GlassAppBar(title: Text(s.signInTitle)),
      body: ListView(
        padding: const EdgeInsets.all(JSpace.md),
        children: [
          body,
          const SizedBox(height: JSpace.lg),
          TextButton(
            onPressed: () => context.canPop() ? context.pop(user != null) : context.go('/'),
            child: Text(user != null ? s.close : s.later),
          ),
        ],
      ),
    );
  }
}
