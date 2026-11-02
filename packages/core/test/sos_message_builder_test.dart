import 'package:joruri_core/joruri_core.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 10, 7, 21, 14);

  test('English message with a fresh location', () {
    final message = SosMessageBuilder.build(
      language: SosMessageLanguage.en,
      now: now,
      location: SosLocation(
        latitude: 23.8103,
        longitude: 90.4125,
        accuracyMeters: 14.6,
        fixTime: now.subtract(const Duration(seconds: 30)),
      ),
    );
    expect(message, contains('EMERGENCY'));
    expect(message, contains('https://maps.google.com/?q=23.81030,90.41250'));
    expect(message, contains('about 15 m'));
    expect(message, contains('07/10/2026 21:14'));
    expect(message, isNot(contains('Location from')));
  });

  test('old location gets its own time stamp', () {
    final message = SosMessageBuilder.build(
      language: SosMessageLanguage.en,
      now: now,
      location: SosLocation(latitude: 1, longitude: 2, fixTime: DateTime(2026, 10, 7, 20, 0)),
    );
    expect(message, contains('Location from: 07/10/2026 20:00'));
  });

  test('no location says so instead of failing', () {
    final message = SosMessageBuilder.build(language: SosMessageLanguage.bn, now: now);
    expect(message, contains('অবস্থান: পাওয়া যায়নি'));
  });

  test('extra line is trimmed and capped', () {
    final message = SosMessageBuilder.build(
      language: SosMessageLanguage.en,
      now: now,
      extraLine: '  ${'x' * 150}  ',
    );
    expect(message.split('\n')[1].length, SosMessageBuilder.maxExtraLineLength);
  });

  test('LocalizedText falls back to the other language', () {
    const text = LocalizedText(en: 'Police', bn: '');
    expect(text.resolve('bn'), 'Police');
  });
}
