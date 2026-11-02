import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/features/contacts/presentation/contacts_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Add or edit one emergency contact. Accepts Bangla digits.
Future<void> showContactForm(BuildContext context, {EmergencyContact? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ContactForm(existing: existing),
  );
}

class _ContactForm extends ConsumerStatefulWidget {
  const _ContactForm({this.existing});

  final EmergencyContact? existing;

  @override
  ConsumerState<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _phone = TextEditingController(
      text: existing == null ? '' : BdPhone.display(existing.phone).replaceAll('-', ''),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = BdPhone.normalizeContact(_phone.text)!;
    final existing = widget.existing;
    final contact = existing == null
        ? EmergencyContact(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: _name.text.trim(),
            phone: phone,
          )
        : existing.copyWith(name: _name.text.trim(), phone: phone);
    await ref.read(contactsProvider.notifier).save(contact);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        JSpace.lg,
        0,
        JSpace.lg,
        MediaQuery.viewInsetsOf(context).bottom + JSpace.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? s.addContact : s.editContact,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: JSpace.md),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: s.contactName, border: const OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? s.nameRequired : null,
            ),
            const SizedBox(height: JSpace.md),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: s.contactPhone,
                hintText: '01712345678',
                border: const OutlineInputBorder(),
              ),
              validator: (v) => BdPhone.normalizeContact(v ?? '') == null ? s.invalidPhone : null,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: JSpace.lg),
            FilledButton(onPressed: _save, child: Text(s.save)),
          ],
        ),
      ),
    );
  }
}
