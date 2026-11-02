import 'package:flutter_test/flutter_test.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/features/profile/data/profile_sync.dart';
import 'package:joruri_bd/features/profile/domain/user_profile.dart';

UserProfile _profile({bool donor = true, bool consent = true, bool available = true}) => UserProfile(
      name: 'Rahim',
      phone: '+8801712345678',
      bloodGroup: BloodGroup.aPos,
      districtId: 'dhaka',
      area: 'Mirpur',
      donor: donor,
      consent: consent,
      available: available,
    );

void main() {
  test('profile updates never send admin-controlled fields', () {
    final fields = ProfileSync.ownDonorFields(_profile(), '2026-10-09T00:00:00Z');
    expect(fields.keys.toSet(), {
      'name', 'bloodGroup', 'phone', 'districtId', 'area', 'available', 'shareConsent', 'updatedAt',
    });
    for (final adminField in ['hidden', 'verified', 'uid', 'source', 'createdAt']) {
      expect(fields.containsKey(adminField), isFalse, reason: adminField);
    }
  });

  test('a new listing starts visible but NOT verified, owned by the user', () {
    final doc = ProfileSync.newDonorDocument(_profile(), 'u1', 'now');
    expect(doc['hidden'], isFalse);
    expect(doc['verified'], isFalse);
    expect(doc['uid'], 'u1');
    expect(doc['id'], 'u1');
    expect(doc['source'], 'app');
    expect(doc['shareConsent'], isTrue);
  });

  test('withdrawing consent switches the listing off instead of deleting it', () {
    final fields = ProfileSync.ownDonorFields(_profile(consent: false), 'now');
    expect(fields['shareConsent'], isFalse);
    expect(fields['available'], isFalse);
  });

  test('not wanting to donate also means not listed and not available', () {
    final fields = ProfileSync.ownDonorFields(_profile(donor: false), 'now');
    expect(fields['shareConsent'], isFalse);
    expect(fields['available'], isFalse);
  });

  test('an unavailable consenting donor stays listed but unavailable', () {
    final fields = ProfileSync.ownDonorFields(_profile(available: false), 'now');
    expect(fields['shareConsent'], isTrue);
    expect(fields['available'], isFalse);
  });
}
