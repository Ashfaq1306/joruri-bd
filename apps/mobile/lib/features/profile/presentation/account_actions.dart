import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/firebase/google_auth.dart';
import 'package:joruri_bd/core/firebase/password_auth.dart';
import 'package:joruri_bd/features/profile/data/account_service.dart';
import 'package:joruri_bd/features/profile/data/profile_sync.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// "Log out": saves the latest profile and contacts with the account, then
/// removes them from this phone. Logging in again brings them back.
Future<void> confirmLogOut(BuildContext context, WidgetRef ref) async {
  final s = context.s;
  final messenger = ScaffoldMessenger.of(context);
  final yes = await _ask(context, title: s.logOutTitle, body: s.logOutBody, action: s.signOut);
  if (!yes || !context.mounted) return;

  final account = ref.read(accountServiceProvider);
  final saved = await _withProgress(context, s.loggingOut, account.saveBeforeLogOut);
  if (!context.mounted) return;
  final lost = saved == SyncStatus.waitingForNetwork || saved == SyncStatus.failed || saved == SyncStatus.notAllowed;
  if (lost) {
    final anyway = await _ask(
      context,
      title: s.logOutUnsavedTitle,
      body: s.logOutUnsavedBody,
      action: s.logOutAnyway,
      danger: true,
    );
    if (!anyway || !context.mounted) return;
  }
  await account.logOut();
  messenger.showSnackBar(SnackBar(content: Text(s.loggedOut)));
}

/// "Delete my data": deletes the account, the donor listing and the profile
/// online, then everything the app saved on this phone.
Future<void> confirmDeleteMyData(BuildContext context, WidgetRef ref) async {
  final s = context.s;
  final messenger = ScaffoldMessenger.of(context);
  final signedIn = ref.read(signedInProvider);
  final yes = await _ask(
    context,
    title: s.deleteLocalData,
    body: signedIn ? s.deleteMyDataAccountBody : s.deleteLocalDataBody,
    action: signedIn ? s.deleteForever : s.delete,
    danger: true,
  );
  if (!yes || !context.mounted) return;

  final account = ref.read(accountServiceProvider);
  var result = await _withProgress(context, s.deletingData, account.deleteEverything);
  // Firebase wants a fresh login before an account is deleted.
  if (result == DeleteResult.needsLogin && context.mounted) {
    final confirmed = await _confirmItsYou(context, ref);
    if (!confirmed || !context.mounted) return;
    result = await _withProgress(context, s.deletingData, account.deleteEverything);
  }
  if (result == DeleteResult.deleted) account.restartApp();
  messenger.showSnackBar(SnackBar(
    content: Text(switch (result) {
      DeleteResult.deleted => signedIn ? s.dataDeleted : s.localDataDeleted,
      DeleteResult.noInternet => s.deleteNeedsInternet,
      DeleteResult.needsLogin || DeleteResult.failed => s.deleteFailed,
    }),
  ));
}

Future<bool> _confirmItsYou(BuildContext context, WidgetRef ref) async {
  final account = ref.read(accountServiceProvider);
  final method = await account.loginMethod();
  if (!context.mounted) return false;
  final s = context.s;
  switch (method) {
    case LoginMethod.password:
      final email = await account.email() ?? '';
      if (!context.mounted) return false;
      return await showDialog<bool>(
            context: context,
            builder: (_) => _PasswordDialog(email: email),
          ) ??
          false;
    case LoginMethod.google:
      final go = await _ask(context, title: s.confirmItsYou, body: s.confirmGoogleToDelete, action: s.continueWithGoogle);
      if (!go) return false;
      final r = await ref.read(googleAuthProvider).reauthenticate();
      return r == SignInResult.signedIn;
    case LoginMethod.other:
      await _ask(context, title: s.confirmItsYou, body: s.confirmOtherToDelete, action: s.close, cancel: false);
      return false;
  }
}

class _PasswordDialog extends ConsumerStatefulWidget {
  const _PasswordDialog({required this.email});

  final String email;

  @override
  ConsumerState<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends ConsumerState<_PasswordDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidden = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.s;
    if (_password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ref.read(passwordAuthProvider).confirm(_password.text);
    if (!mounted) return;
    if (r == PasswordResult.signedIn) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = switch (r) {
        PasswordResult.wrongPassword => '${s.wrongEmailOrPassword}\n${s.noPasswordYetHint}',
        PasswordResult.tooMany => s.tooManyTries,
        PasswordResult.noInternet => s.noInternetTryAgain,
        _ => s.deleteFailed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.confirmItsYou),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.confirmPasswordToDelete(widget.email)),
          const SizedBox(height: JSpace.md),
          TextField(
            controller: _password,
            obscureText: _hidden,
            autofocus: true,
            enabled: !_busy,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: s.passwordLabel,
              border: const OutlineInputBorder(),
              errorText: _error,
              errorMaxLines: 4,
              suffixIcon: IconButton(
                tooltip: _hidden ? s.showPassword : s.hidePassword,
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(s.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: JColors.sos),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(s.deleteForever),
        ),
      ],
    );
  }
}

Future<bool> _ask(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  bool danger = false,
  bool cancel = true,
}) async {
  final s = context.s;
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            if (cancel) TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(s.cancel)),
            FilledButton(
              style: danger ? FilledButton.styleFrom(backgroundColor: JColors.sos) : null,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
}

/// Runs [task] behind a small "please wait" dialog that cannot be dismissed.
Future<T> _withProgress<T>(BuildContext context, String message, Future<T> Function() task) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: JSpace.md),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}
