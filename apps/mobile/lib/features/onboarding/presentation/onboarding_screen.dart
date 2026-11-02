import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/features/contacts/presentation/contacts_list.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/features/profile/presentation/profile_form.dart';
import 'package:joruri_bd/features/settings/domain/app_settings.dart';
import 'package:joruri_bd/features/settings/presentation/permissions_section.dart';
import 'package:joruri_bd/features/settings/presentation/settings_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Four short steps: language, account, contacts, SOS. The app follows the
/// phone's light/dark setting; people can change it later in Settings. The account
/// asks for name, mobile, blood group and district; it can be skipped
/// ("not now"), because SOS must work for someone in an emergency who has
/// just installed the app.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  final _profileForm = GlobalKey<ProfileFormState>();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    setState(() => _page = page);
    _pages.animateToPage(page, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _saveAccount() async {
    final profile = _profileForm.currentState?.submit();
    if (profile == null) return;
    await ref.read(profileProvider.notifier).save(profile);
    if (!mounted) return;
    // Sign in with Google now (or "Later"), then continue.
    await context.push<bool>('/sign-in');
    if (mounted) _go(2);
  }

  void _finish() =>
      ref.read(settingsProvider.notifier).change((c) => c.copyWith(onboardingDone: true));

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    Widget page({required String title, String? body, required List<Widget> children}) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(JSpace.lg, JSpace.xl, JSpace.lg, JSpace.lg),
        children: [
          Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (body != null) ...[
            const SizedBox(height: JSpace.sm),
            Text(body, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: JSpace.lg),
          ...children,
        ],
      );
    }

    final steps = <Widget>[
      // 1. Language (shown in both languages, before one is chosen)
      ListView(
        padding: const EdgeInsets.fromLTRB(JSpace.lg, 32, JSpace.lg, JSpace.lg),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/images/logo_full.png',
                width: 240,
                cacheWidth: (240 * MediaQuery.devicePixelRatioOf(context)).round(),
                semanticLabel: 'Joruri',
              ),
            ),
          ),
          const SizedBox(height: JSpace.lg),
          Text(
            'জরুরি বিডি-তে স্বাগতম\nWelcome to Joruri BD',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: JSpace.xl),
          Text('ভাষা বেছে নিন · Choose language', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: JSpace.md),
          ChoiceCard(
            leading: const Text('🇧🇩', style: TextStyle(fontSize: 28)),
            title: 'বাংলা',
            selected: settings.languageCode == 'bn',
            onTap: () async {
              await controller.change((c) => c.copyWith(languageCode: 'bn'));
              _go(1);
            },
          ),
          const SizedBox(height: JSpace.sm),
          ChoiceCard(
            leading: const Text('🇬🇧', style: TextStyle(fontSize: 28)),
            title: 'English',
            selected: settings.languageCode == 'en',
            onTap: () async {
              await controller.change((c) => c.copyWith(languageCode: 'en'));
              _go(1);
            },
          ),
        ],
      ),
      // 2. Account (required fields: name, mobile, blood group, district)
      page(
        title: s.createAccount,
        body: s.accountWhy,
        children: [ProfileForm(key: _profileForm)],
      ),
      // 3. Contacts
      page(title: s.contactsStepTitle, body: s.contactsStepBody, children: const [ContactsList()]),
      // 4. SOS mode and permissions
      page(
        title: s.sosStepTitle,
        children: [
          ChoiceCard(
            title: s.sosModeCountdown,
            subtitle: s.sosModeCountdownBody,
            selected: settings.sosMode == SosMode.countdown,
            onTap: () => controller.change((c) => c.copyWith(sosMode: SosMode.countdown)),
          ),
          const SizedBox(height: JSpace.sm),
          ChoiceCard(
            title: s.sosModeInstant,
            subtitle: s.sosModeInstantBody,
            selected: settings.sosMode == SosMode.instant,
            onTap: () => controller.change((c) => c.copyWith(sosMode: SosMode.instant)),
          ),
          const SizedBox(height: JSpace.lg),
          Text(s.permissionsTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: JSpace.xs),
          Text(s.permissionsBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: JSpace.md),
          const PermissionsSection(),
        ],
      ),
    ];

    final last = _page == steps.length - 1;
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_page + 1) / steps.length,
              backgroundColor: Colors.transparent,
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: steps,
              ),
            ),
            if (_page > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(JSpace.lg, JSpace.sm, JSpace.lg, JSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: last
                          ? _finish
                          : _page == 1
                              ? _saveAccount
                              : () => _go(_page + 1),
                      child: Text(
                        last ? s.getStarted : (_page == 1 ? s.saveAccount : s.next),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(onPressed: () => _go(_page - 1), child: Text(s.back)),
                        const Spacer(),
                        if (_page == 1)
                          Flexible(
                            child: TextButton(
                              onPressed: () => _go(2),
                              child: Text(s.skipAccount, textAlign: TextAlign.end),
                            ),
                          ),
                        if (_page == 2) TextButton(onPressed: () => _go(_page + 1), child: Text(s.skip)),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }
}
