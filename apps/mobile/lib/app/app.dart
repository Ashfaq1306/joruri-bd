import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/app/router.dart';
import 'package:joruri_bd/core/firebase/email_link_auth.dart';
import 'package:joruri_bd/features/update/update_installer.dart';
import 'package:joruri_bd/features/settings/presentation/settings_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

class JoruriApp extends ConsumerWidget {
  const JoruriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    final languageCode = settings.languageCode;
    // Always running: e-mail sign-in links, and automatic update downloads.
    ref.watch(signInLinkListenerProvider);
    ref.listen(updateInstallerProvider, (_, __) {});

    return MaterialApp.router(
      onGenerateTitle: (context) => context.s.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: settings.themeMode,
      theme: buildJoruriTheme(brightness: Brightness.light, easyMode: settings.easyMode),
      darkTheme: buildJoruriTheme(brightness: Brightness.dark, easyMode: settings.easyMode),
      locale: languageCode == null ? null : Locale(languageCode),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        if (!settings.easyMode || child == null) return child ?? const SizedBox.shrink();
        // Easy Mode: text is at least 1.3x, more if the phone already asks for more.
        final media = MediaQuery.of(context);
        final scaler = media.textScaler.scale(1) < 1.3 ? const TextScaler.linear(1.3) : media.textScaler;
        return MediaQuery(data: media.copyWith(textScaler: scaler), child: child);
      },
    );
  }
}
