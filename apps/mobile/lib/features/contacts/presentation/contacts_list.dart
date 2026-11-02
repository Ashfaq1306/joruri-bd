import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/features/contacts/presentation/contact_form_sheet.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// The contact list with add, edit, reorder-to-first and remove.
/// Used by onboarding and by the contacts screen.
class ContactsList extends ConsumerWidget {
  const ContactsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final contacts = ref.watch(contactsProvider);
    final controller = ref.read(contactsProvider.notifier);
    final theme = Theme.of(context);

    Future<void> confirmRemove(EmergencyContact c) async {
      final yes = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(s.removeContactQuestion),
          content: Text(c.name),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(s.cancel)),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(s.delete)),
          ],
        ),
      );
      if (yes ?? false) await controller.remove(c.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < contacts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: JSpace.sm),
            child: ListTile(
              minVerticalPadding: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(JSize.radius),
                side: BorderSide(color: i == 0 ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
              ),
              leading: CircleAvatar(child: Text(contacts[i].name.characters.first.toUpperCase())),
              title: Text(contacts[i].name, style: theme.textTheme.titleMedium),
              subtitle: Text(
                i == 0
                    ? '${BdPhone.display(contacts[i].phone)} · ${s.primaryContact}'
                    : BdPhone.display(contacts[i].phone),
              ),
              onTap: () => showContactForm(context, existing: contacts[i]),
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'primary') controller.makePrimary(contacts[i].id);
                  if (action == 'edit') showContactForm(context, existing: contacts[i]);
                  if (action == 'delete') confirmRemove(contacts[i]);
                },
                itemBuilder: (_) => [
                  if (i != 0) PopupMenuItem(value: 'primary', child: Text(s.makePrimary)),
                  PopupMenuItem(value: 'edit', child: Text(s.edit)),
                  PopupMenuItem(value: 'delete', child: Text(s.delete)),
                ],
              ),
            ),
          ),
        if (controller.canAdd)
          OutlinedButton.icon(
            onPressed: () => showContactForm(context),
            icon: const Icon(Icons.person_add),
            label: Text(s.addContact),
          )
        else
          Text(s.maxContactsReached, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
