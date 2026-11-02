import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/core/firebase/firebase_ready.dart';

/// The live online donor list for the given blood groups ("A+,O-").
///
/// null = not available: signed out (the server only shows donor listings to
/// signed-in users), or online features not set up. The two filters below
/// are also required by the security rules: without them the query is
/// refused, so the server, not this code, guarantees only consented and
/// visible donors are returned.
/// The person's own entry comes back with id "me" so it shows "You".
final remoteDonorsProvider = StreamProvider.family<List<Donor>?, String>((ref, groups) async* {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) {
    yield null;
    return;
  }
  yield* FirebaseFirestore.instance
      .collection('donors')
      .where('shareConsent', isEqualTo: true)
      .where('hidden', isEqualTo: false)
      .where('bloodGroup', whereIn: groups.split(','))
      .limit(300)
      .snapshots()
      .map((snap) {
    final out = <Donor>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['shareConsent'] != true || data['hidden'] == true) continue;
      try {
        out.add(Donor.fromJson({...data, 'id': doc.id == user.uid ? 'me' : doc.id}));
      } catch (_) {}
    }
    return out;
  });
});
