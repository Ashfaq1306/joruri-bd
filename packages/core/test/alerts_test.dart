import 'dart:io';

import 'package:joruri_core/joruri_core.dart';
import 'package:test/test.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  group('BMD CAP warnings', () {
    test('heavy rain in the hill districts: both languages, the five districts', () {
      final a = parseCapAlert(fixture('bmd/rain_hills.xml'))!;
      expect(a.id, 'bmd-778339bb-aa90-4b4f-aad5-687abf172332');
      expect(a.hazard, Hazard.rain);
      expect(a.level, AlertLevel.warning);
      expect(a.headline.en, contains('Heavy Rainfall'));
      expect(a.headline.bn, isNotEmpty);
      expect(a.districts, containsAll(['bandarban', 'chattogram', 'coxs-bazar', 'khagrachhari', 'rangamati']));
      expect(a.districts, isNot(contains('dhaka')));
      expect(a.districts, isNot(contains('rangpur')));
      expect(a.concerns('rangamati'), isTrue);
      expect(a.concerns('sylhet'), isFalse);
      expect(a.expires, DateTime.utc(2026, 10, 1, 12));
    });

    test('warning for three divisions covers their districts', () {
      final a = parseCapAlert(fixture('bmd/rain_divisions.xml'))!;
      expect(a.hazard, Hazard.rain);
      for (final d in ['sylhet', 'sunamganj', 'mymensingh', 'netrokona', 'rangpur', 'kurigram']) {
        expect(a.districts, contains(d), reason: d);
      }
      expect(a.districts, isNot(contains('dhaka')));
      expect(a.districts, isNot(contains('khulna')));
    });

    test('cyclone bulletin: signal 3 at the four sea ports', () {
      final a = parseCapAlert(fixture('bmd/signal3.xml'))!;
      expect(a.hazard, Hazard.cyclone);
      expect(a.signal, 3);
      expect(a.level, AlertLevel.watch);
      expect(a.districts, containsAll(['chattogram', 'coxs-bazar', 'bagerhat', 'patuakhali']));
      expect(a.shouldNotify(districtId: 'coxs-bazar'), isTrue);
      expect(a.shouldNotify(districtId: 'rajshahi'), isFalse);
    });

    test('distant signal 1 is for information only', () {
      final a = parseCapAlert(fixture('bmd/signal1_distant.xml'))!;
      expect(a.hazard, Hazard.cyclone);
      expect(a.signal, 1);
      expect(a.level, AlertLevel.advisory);
      expect(a.shouldNotify(districtId: 'chattogram'), isFalse);
    });

    test('feed lists the CAP messages', () {
      final items = parseCapFeed(fixture('bmd/rss.xml'));
      expect(items, isNotEmpty);
      expect(items.first.url, startsWith('https://cap.bmd.gov.bd/api/cap/'));
      expect(items.first.published, isNotNull);
    });

    test('survives junk', () {
      expect(parseCapAlert('not xml'), isNull);
      expect(parseCapAlert('<alert/>'), isNull);
      expect(parseCapFeed('<html>'), isEmpty);
    });

    test('round trip through JSON', () {
      final a = parseCapAlert(fixture('bmd/signal3.xml'))!;
      final b = HazardAlert.fromJson(a.toJson());
      expect(b.id, a.id);
      expect(b.districts, a.districts);
      expect(b.signal, 3);
      expect(b.level, a.level);
      expect(b.headline.bn, a.headline.bn);
      final push = HazardAlert.fromJson(a.toPushJson());
      expect(push.districts, a.districts);
      expect(push.description.en.length, lessThanOrEqualTo(300));
    });
  });

  group('storm signals', () {
    test('reads the number in words or digits', () {
      expect(stormSignal('keep hoisted great danger signal number ten (10)'), 10);
      expect(stormSignal('hoist danger signal No. 7'), 7);
      expect(stormSignal('keep hoisted distant cautionary signal number one (R) one'), 1);
      expect(stormSignal('lower the danger signal number seven and hoist local cautionary signal number three (3)'), 3);
      expect(stormSignal('no signals today'), isNull);
    });

    test('every signal has a meaning in both languages', () {
      expect(StormSignal.all.map((s) => s.number), List.generate(11, (i) => i + 1));
      for (final s in StormSignal.all) {
        expect(s.meaning.en, isNotEmpty);
        expect(s.meaning.bn, isNotEmpty);
        expect(s.whatToDo.bn, isNotEmpty);
      }
      expect(StormSignal.of(8)!.level, AlertLevel.emergency);
      expect(StormSignal.of(5)!.level, AlertLevel.warning);
    });
  });

  group('place names', () {
    test('divisions and districts', () {
      expect(districtsNamedIn('Residents in low-lying areas of Sylhet division should take care'),
          containsAll(['sylhet', 'sunamganj', 'habiganj', 'moulvibazar']));
      expect(districtsNamedIn('Dhaka district'), ['dhaka']);
      expect(districtsNamedIn("ports of Chittagong, Cox'S Bazar, Mongla and Payra"),
          ['bagerhat', 'chattogram', 'coxs-bazar', 'patuakhali']);
    });
  });

  group('USGS earthquakes', () {
    test('only quakes that can be felt in Bangladesh', () {
      final all = UsgsQuakes.parse(fixture('usgs.geojson'));
      expect(all, isNotEmpty);
      for (final a in all) {
        expect(a.hazard, Hazard.earthquake);
        expect(a.districts, isNotEmpty);
        expect(a.quake, isNotNull);
        expect(a.headline.bn, contains('মাত্রার ভূমিকম্প'));
      }
    });

    test('a strong quake near Sylhet: emergency; a moderate one is not felt in Satkhira', () {
      final a = UsgsQuakes.fromFeature({
        'id': 'test1',
        'properties': {'mag': 6.1, 'time': DateTime.utc(2026, 11, 1).millisecondsSinceEpoch, 'place': 'near Sylhet', 'type': 'earthquake'},
        'geometry': {'coordinates': [91.9, 24.95, 10]},
      })!;
      expect(a.level, AlertLevel.emergency);
      expect(a.quake!.nearestDistrictId, 'sylhet');
      expect(a.headline.en, contains('Sylhet'));
      expect(a.concerns('sylhet'), isTrue);
      expect(a.concerns('dhaka'), isTrue); // 6.1 is felt ~400 km away
      final b = UsgsQuakes.fromFeature({
        'id': 'test2',
        'properties': {'mag': 5.1, 'time': 0, 'place': 'near Sylhet'},
        'geometry': {'coordinates': [91.9, 24.95, 10]},
      })!;
      expect(b.level, AlertLevel.warning);
      expect(b.concerns('dhaka'), isTrue);
      expect(b.concerns('satkhira'), isFalse);
      expect(a.expires, a.sent.add(UsgsQuakes.life));
    });

    test('a small quake far away is left out', () {
      final a = UsgsQuakes.fromFeature({
        'id': 'far',
        'properties': {'mag': 4.2, 'time': 0, 'place': 'Tibet'},
        'geometry': {'coordinates': [88.0, 30.5, 10]},
      });
      expect(a, isNull);
    });
  });

  group('lists', () {
    HazardAlert alert(String id, AlertLevel level, DateTime sent, {DateTime? expires, List<String> districts = const ['dhaka']}) =>
        HazardAlert(
          id: id,
          source: AlertSource.team,
          hazard: Hazard.flood,
          level: level,
          headline: const LocalizedText(en: 'x', bn: 'x'),
          sent: sent,
          expires: expires,
          districts: districts,
        );

    test('active, most serious first, expired ones dropped', () {
      final now = DateTime.utc(2026, 11, 10, 12);
      final list = activeAlerts([
        alert('old', AlertLevel.emergency, now.subtract(const Duration(days: 3))),
        alert('a', AlertLevel.watch, now.subtract(const Duration(hours: 1))),
        alert('b', AlertLevel.warning, now.subtract(const Duration(hours: 2)), expires: now.add(const Duration(hours: 5))),
        alert('a', AlertLevel.watch, now),
      ], now);
      expect(list.map((a) => a.id), ['b', 'a']);
    });

    test('team alert for a division and push off', () {
      final a = HazardAlert.fromJson({
        'id': 'team-1',
        'hazard': 'flood',
        'level': 'warning',
        'headline': {'en': 'Flood', 'bn': 'বন্যা'},
        'divisions': ['sylhet'],
        'sent': '2026-11-10T00:00:00Z',
        'push': false,
      });
      expect(a.districts, hasLength(4));
      expect(a.concerns('sunamganj'), isTrue);
      expect(a.shouldNotify(districtId: 'sunamganj'), isFalse);
    });

    test('geometry', () {
      expect(distanceKm(23.81, 90.41, 22.34, 91.83), closeTo(216, 10)); // Dhaka–Chattogram
      expect(pointInPolygon(1, 1, [(0, 0), (0, 2), (2, 2), (2, 0)]), isTrue);
      expect(pointInPolygon(3, 1, [(0, 0), (0, 2), (2, 2), (2, 0)]), isFalse);
      expect(bdDistrictAreas, hasLength(64));
    });
  });
}
