import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/features/blood/presentation/blood_query_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Step 1: which blood group is needed. Eight large buttons, nothing else.
class BloodGroupScreen extends ConsumerWidget {
  const BloodGroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: GlassAppBar(title: Text(s.needBlood)),
      body: ListView(
        padding: const EdgeInsets.all(JSpace.md),
        children: [
          Text(s.chooseBloodGroup, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: JSpace.xs),
          Text(s.bloodGroupHint, style: theme.textTheme.bodyLarge),
          const SizedBox(height: JSpace.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: [
              for (final group in BloodGroup.values)
                Semantics(
                  button: true,
                  label: group.label,
                  excludeSemantics: true,
                  child: Material(
                    color: dark ? JColors.nightSurface : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(JSize.radius),
                      side: const BorderSide(color: JColors.blood, width: 2),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(JSize.radius),
                      onTap: () {
                        ref.read(bloodQueryProvider.notifier).setGroup(group);
                        context.push('/blood/donors');
                      },
                      child: Center(
                        child: Text(
                          group.label,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: dark ? const Color(0xFFFF8A80) : JColors.blood,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: JSpace.lg),
          Text(s.bloodDisclaimer, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
