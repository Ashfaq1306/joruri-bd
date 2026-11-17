import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/firebase/email_link_auth.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/firebase/google_auth.dart';
import 'package:joruri_bd/core/firebase/password_auth.dart';
import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/features/profile/presentation/profile_sync_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Log in, or create an account once: e-mail and password, or Google (both
/// free on the Firebase Spark plan, with no daily limit). Firebase keeps the
/// person logged in on this phone until they sign out. After logging in, a
/// profile saved with the account comes back; otherwise the profile on the
/// phone is put online. Returns true when signed in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.startWithCreate = false});

  /// Open on "Create account" instead of "Log in".
  final bool startWithCreate;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  String? _error;
  String? _info;
  late bool _create = widget.startWithCreate;
  bool _showPassword = false;
  // Sign in by itself only once, and only with the address saved when an
  // e-mail link was sent (older app versions sent those).
  late bool _autoTried = ref.read(emailLinkAuthProvider).pendingEmail == null;
  late final _email = TextEditingController(text: ref.read(emailLinkAuthProvider).pendingEmail ?? '');
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _start() => setState(() {
        _busy = true;
        _error = null;
        _info = null;
      });

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  Future<void> _done() async {
    TextInput.finishAutofillContext();
    // A profile saved with the account comes back on this phone; otherwise
    // the profile on this phone is put online. Status shows on the profile card.
    final restored = await ref.read(profileProvider.notifier).restoreFromAccount();
    if (!restored) await ref.read(profileSyncStatusProvider.notifier).sync();
    if (!mounted) return;
    if (restored) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.profileRestored)));
    }
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/');
    }
  }

  String _passwordMessage(PasswordResult r) {
    final s = context.s;
    return switch (r) {
      PasswordResult.invalidEmail => s.emailInvalid,
      PasswordResult.weakPassword => s.passwordTooShort,
      PasswordResult.wrongPassword => s.wrongEmailOrPassword,
      PasswordResult.emailInUse => s.emailAlreadyHasAccount,
      PasswordResult.tooMany => s.tooManyTries,
      PasswordResult.unavailable => s.signInNotAvailable,
      PasswordResult.noInternet => s.noInternetTryAgain,
      PasswordResult.signedIn || PasswordResult.resetSent || PasswordResult.failed => s.signInFailed,
    };
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final s = context.s;
    if (!EmailLinkAuth.looksLikeEmail(_email.text)) return _fail(s.emailInvalid);
    if (_password.text.length < PasswordAuth.minLength) return _fail(s.passwordTooShort);
    if (_create && _password.text != _confirm.text) return _fail(s.passwordsDontMatch);
    _start();
    final auth = ref.read(passwordAuthProvider);
    final r = _create ? await auth.create(_email.text, _password.text) : await auth.logIn(_email.text, _password.text);
    if (!mounted) return;
    if (r == PasswordResult.signedIn) {
      await _done();
    } else {
      // An address that already has an account: switch to "Log in".
      if (r == PasswordResult.emailInUse) setState(() => _create = false);
      _fail(_passwordMessage(r));
    }
  }

  Future<void> _forgot() async {
    FocusScope.of(context).unfocus();
    if (!EmailLinkAuth.looksLikeEmail(_email.text)) return _fail(context.s.emailInvalid);
    _start();
    final r = await ref.read(passwordAuthProvider).sendReset(_email.text, languageCode: context.s.languageCode);
    if (!mounted) return;
    if (r == PasswordResult.resetSent) {
      setState(() {
        _busy = false;
        _info = context.s.passwordResetSent(_email.text.trim());
      });
    } else {
      _fail(_passwordMessage(r));
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

  String _linkMessage(EmailLinkResult r) {
    final s = context.s;
    return switch (r) {
      EmailLinkResult.invalidEmail => s.emailInvalid,
      EmailLinkResult.emailMismatch => s.signInEmailMismatch,
      EmailLinkResult.linkInvalid => s.signInLinkInvalid,
      EmailLinkResult.tooMany => s.tooManyTries,
      EmailLinkResult.dailyLimit => s.emailDailyLimit,
      EmailLinkResult.unavailable => s.signInNotAvailable,
      EmailLinkResult.sent || EmailLinkResult.signedIn || EmailLinkResult.failed => s.signInFailed,
    };
  }

  /// A sign-in link e-mailed by an older version of the app.
  Future<void> _finishLink(String link) async {
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
      _fail(_linkMessage(r));
    }
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _finishLink(link));
    }

    Widget message(String text, Color color, IconData icon) => Container(
          margin: const EdgeInsets.only(top: JSpace.sm),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(JSize.radius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
            ],
          ),
        );
    final messages = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) message(_error!, theme.colorScheme.error, Icons.error_outline),
        if (_info != null) message(_info!, JColors.ok, Icons.mark_email_read_outlined),
      ],
    );
    Widget spinnerOr(IconData icon) => _busy
        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : Icon(icon);
    final emailField = TextField(
      controller: _email,
      enabled: !_busy,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
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
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.verified_user_outlined, size: 48, color: JColors.ok),
          const SizedBox(height: JSpace.sm),
          Text(s.signedInAs(user.email ?? user.displayName ?? ''),
              textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: JSpace.xs),
          Text(s.stayLoggedIn, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ],
      );
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
          FilledButton.icon(
            onPressed: _busy ? null : () => _finishLink(link),
            icon: spinnerOr(Icons.login),
            label: Text(s.finishSignIn),
          ),
          messages,
        ],
      );
    } else {
      final passwordField = TextField(
        controller: _password,
        enabled: !_busy,
        obscureText: !_showPassword,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: _create ? TextInputAction.next : TextInputAction.done,
        onSubmitted: _create ? null : (_) => _submit(),
        autofillHints: [_create ? AutofillHints.newPassword : AutofillHints.password],
        decoration: InputDecoration(
          labelText: s.passwordLabel,
          helperText: _create ? s.passwordTooShort : null,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            tooltip: _showPassword ? s.hidePassword : s.showPassword,
            icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
      );
      body = AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(s.logIn), icon: const Icon(Icons.login)),
                ButtonSegment(value: true, label: Text(s.createAccountTab), icon: const Icon(Icons.person_add_alt)),
              ],
              selected: {_create},
              showSelectedIcon: false,
              onSelectionChanged: _busy
                  ? null
                  : (v) => setState(() {
                        _create = v.first;
                        _error = null;
                        _info = null;
                      }),
            ),
            const SizedBox(height: JSpace.md),
            Text(_create ? s.createAccountBody : s.logInBody, style: theme.textTheme.bodyLarge),
            const SizedBox(height: JSpace.md),
            emailField,
            const SizedBox(height: JSpace.sm),
            passwordField,
            if (_create) ...[
              const SizedBox(height: JSpace.sm),
              TextField(
                controller: _confirm,
                enabled: !_busy,
                obscureText: !_showPassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(labelText: s.confirmPasswordLabel, prefixIcon: const Icon(Icons.lock_outline)),
              ),
            ],
            const SizedBox(height: JSpace.md),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: spinnerOr(_create ? Icons.person_add_alt : Icons.login),
              label: Text(_create ? s.createAccountTab : s.logIn),
            ),
            if (!_create)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _busy ? null : _forgot, child: Text(s.forgotPassword)),
              ),
            messages,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: JSpace.md),
              child: Row(children: [
                const Expanded(child: Divider()),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(s.orWord)),
                const Expanded(child: Divider()),
              ]),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _signInGoogle,
              icon: const Icon(Icons.account_circle_outlined),
              label: Text(s.continueWithGoogle),
            ),
            const SizedBox(height: JSpace.md),
            Text(s.stayLoggedIn, style: theme.textTheme.bodySmall),
            const SizedBox(height: JSpace.xs),
            Text(s.phoneSelfDeclared, style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: GlassAppBar(title: Text(user != null ? s.signInTitle : s.logInTitle)),
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
