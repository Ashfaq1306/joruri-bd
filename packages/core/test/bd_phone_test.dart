import 'package:joruri_core/joruri_core.dart';
import 'package:test/test.dart';

void main() {
  group('BdPhone.normalizeMobile', () {
    test('accepts local, +880 and 880 forms', () {
      expect(BdPhone.normalizeMobile('01712345678'), '+8801712345678');
      expect(BdPhone.normalizeMobile('+8801712345678'), '+8801712345678');
      expect(BdPhone.normalizeMobile('8801712345678'), '+8801712345678');
      expect(BdPhone.normalizeMobile('017-1234 5678'), '+8801712345678');
    });

    test('accepts Bangla digits', () {
      expect(BdPhone.normalizeMobile('০১৭১২৩৪৫৬৭৮'), '+8801712345678');
    });

    test('rejects invalid numbers', () {
      expect(BdPhone.normalizeMobile('01212345678'), isNull); // no 012 operator
      expect(BdPhone.normalizeMobile('0171234567'), isNull); // too short
      expect(BdPhone.normalizeMobile(''), isNull);
    });
  });

  test('normalizeContact keeps landlines, rejects junk', () {
    expect(BdPhone.normalizeContact('02-9123456'), '029123456');
    expect(BdPhone.normalizeContact('12'), isNull);
  });

  test('display formats mobiles', () {
    expect(BdPhone.display('+8801712345678'), '01712-345678');
  });
}
