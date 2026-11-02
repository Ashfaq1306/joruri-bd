import 'package:flutter_test/flutter_test.dart';

import 'package:joruri_bd/core/remote/app_meta.dart';
import 'package:joruri_bd/features/announcements/announcements.dart';

void main() {
  test('split-APK build numbers compare by their base build', () {
    expect(baseBuildNumber('10'), 10);
    expect(baseBuildNumber('2010'), 10); // arm64-v8a
    expect(baseBuildNumber('1010'), 10); // armeabi-v7a
    expect(baseBuildNumber('oops'), 0);
  });

  test('app settings from the website are read safely', () {
    final m = AppMeta.fromJson({
      'latestVersionCode': 12,
      'latestVersionName': ' 1.1.0 ',
      'minVersionCode': '5',
      'apkUrl': 'https://joruri-bd.web.app/download/joruri-bd.apk',
      'notes': {'en': 'Faster', 'bn': 'দ্রুত'},
      'showDraftGuides': false,
    });
    expect(m.latestVersionCode, 12);
    expect(m.latestVersionName, '1.1.0');
    expect(m.minVersionCode, 5);
    expect(m.notes.resolve('bn'), 'দ্রুত');
    expect(m.showDraftGuides, isFalse);
    // Missing switches keep the built-in default.
    expect(m.showUnverifiedContent, isTrue);
  });

  test('announcements respect their date window, both days included', () {
    final a = Announcement.fromJson({
      'id': 'n1',
      'title': {'en': 'Flood warning', 'bn': ''},
      'body': {'en': 'Move to high ground', 'bn': ''},
      'level': 'urgent',
      'startsAt': '2026-07-01',
      'endsAt': '2026-07-03',
    });
    expect(a.level, AnnouncementLevel.urgent);
    expect(a.activeOn(DateTime(2026, 6, 30)), isFalse);
    expect(a.activeOn(DateTime(2026, 7, 1)), isTrue);
    expect(a.activeOn(DateTime(2026, 7, 3, 23, 59)), isTrue);
    expect(a.activeOn(DateTime(2026, 7, 4)), isFalse);
  });

  test('an announcement without dates is always shown; unknown level is info', () {
    final a = Announcement.fromJson({
      'id': 'n2',
      'title': {'en': 'Blood camp', 'bn': 'রক্তদান শিবির'},
      'level': 'something-new',
    });
    expect(a.level, AnnouncementLevel.info);
    expect(a.activeOn(DateTime(2030, 1, 1)), isTrue);
  });
}
