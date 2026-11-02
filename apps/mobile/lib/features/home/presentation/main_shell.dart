import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/l10n/app_strings.dart';

/// Bottom tabs. Outside Home, a red SOS button floats on every tab.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final onHome = navigationShell.currentIndex == 0;
    return Scaffold(
      body: MeshBackground(child: navigationShell),
      floatingActionButton: onHome
          ? null
          : FloatingActionButton.large(
              elevation: 6,
              heroTag: 'sos-fab',
              tooltip: s.sosHint,
              backgroundColor: JColors.sos,
              foregroundColor: Colors.white,
              onPressed: () => context.push('/sos'),
              child: const Text('SOS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0x59000000) : const Color(0x14103026),
            ),
          ),
        ),
        child: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) =>
            navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: s.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: s.navGuides,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: s.navSettings,
          ),
        ],
      ),
      ),
    );
  }
}
