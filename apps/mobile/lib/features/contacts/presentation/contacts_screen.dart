import 'package:flutter/material.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_list.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: GlassAppBar(title: Text(s.emergencyContacts)),
      body: ListView(
        padding: const EdgeInsets.all(JSpace.md),
        children: [
          Text(s.contactsExplainer, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: JSpace.md),
          const ContactsList(),
        ],
      ),
    );
  }
}
