import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/firebase/google_auth.dart';
import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/features/profile/presentation/profile_sync_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Sign in with Google (free on the Firebase Spark plan). After signing in,
/// the profile saved on the phone is put online. Returns true when signed in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(googleAuthProvider).signIn();
    if (!mounted) return;
    switch (result) {
      case SignInResult.signedIn:
        // Put the saved profile online now; the status shows on the profile card.
        await ref.read(profileSyncStatusProvider.notifier).sync();
        if (!mounted) return;
        context.pop(true);
        return;
      case SignInResult.cancelled:
        setState(() => _busy = false);
        return;
      case SignInResult.unavailable:
        setState(() {
          _busy = false;
          _error = context.s.signInNotAvailable;
        });
        return;
      case SignInResult.failed:
        setState(() {
          _busy = false;
          _error = context.s.signInFailed;
        });
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final ready = ref.watch(firebaseReadyProvider);
    final user = ref.watch(authUserProvider).valueOrNull;

    Widget body;
    if (ready.isLoading) {
      body = const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    } else if (ready.valueOrNull != true) {
      body = Text(s.onlineNotReady, style: theme.textTheme.titleMedium);
    } else if (user != null) {
      body = Text(s.signedInAs(user.email ?? user.displayName ?? ''), style: theme.textTheme.titleMedium);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.signInBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: JSpace.sm),
          Text(s.phoneSelfDeclared, style: theme.textTheme.bodySmall),
          const SizedBox(height: JSpace.lg),
          FilledButton.icon(
            onPressed: _busy ? null : _signIn,
            icon: _busy
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.account_circle_outlined),
            label: Text(s.signInWithGoogle),
          ),
          if (_error != null) ...[
            const SizedBox(height: JSpace.sm),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
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
          TextButton(onPressed: () => context.pop(user != null), child: Text(user != null ? s.close : s.later)),
        ],
      ),
    );
  }
}
