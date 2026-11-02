import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/features/contacts/data/contacts_repository.dart';

final contactsRepositoryProvider = Provider<ContactsRepository>(
  (ref) => ContactsRepository(ref.watch(sharedPreferencesProvider)),
);

final contactsProvider =
    NotifierProvider<ContactsController, List<EmergencyContact>>(ContactsController.new);

/// The first contact in the list is the one SOS calls.
class ContactsController extends Notifier<List<EmergencyContact>> {
  @override
  List<EmergencyContact> build() => ref.watch(contactsRepositoryProvider).load();

  bool get canAdd => state.length < AppConfig.maxEmergencyContacts;

  Future<void> save(EmergencyContact contact) async {
    final index = state.indexWhere((c) => c.id == contact.id);
    final next = [...state];
    if (index >= 0) {
      next[index] = contact;
    } else if (canAdd) {
      next.add(contact);
    } else {
      return;
    }
    await _set(next);
  }

  Future<void> remove(String id) => _set(state.where((c) => c.id != id).toList());

  Future<void> makePrimary(String id) async {
    final index = state.indexWhere((c) => c.id == id);
    if (index <= 0) return;
    await _set([state[index], ...state.where((c) => c.id != id)]);
  }

  Future<void> _set(List<EmergencyContact> next) async {
    state = List.unmodifiable(next);
    await ref.read(contactsRepositoryProvider).save(next);
  }
}

/// Calls the first contact, or opens the contacts screen if there is none.
Future<void> callPrimaryContact(BuildContext context, WidgetRef ref) async {
  final contacts = ref.read(contactsProvider);
  if (contacts.isEmpty) {
    context.push('/contacts');
    return;
  }
  await ref.read(phoneServiceProvider).callDirect(contacts.first.phone);
}
