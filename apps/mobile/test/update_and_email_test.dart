import 'package:flutter_test/flutter_test.dart';
import 'package:joruri_bd/core/firebase/email_link_auth.dart';
import 'package:joruri_bd/core/remote/app_meta.dart';

void main() {
  test('meta/app carries the SHA-256 the in-app updater checks', () {
    final m = AppMeta.fromJson({
      'latestVersionCode': 16,
      'apkUrl': 'https://github.com/Ashfaq1306/joruri-bd/releases/download/v1.4.0-build16/joruri-bd.apk',
      'apkSha256': ' 3C2BC0CCA524 ',
      'apkSha256Arm32': 'dd52',
    });
    expect(m.apkSha256, '3c2bc0cca524', reason: 'compared with the lower-case hex digest of the download');
    expect(m.apkSha256Arm32, 'dd52');
    expect(AppMeta.fromJson({}).apkSha256, isEmpty, reason: 'older meta/app without hashes still works');
  });

  test('split-APK build numbers compare by base build', () {
    expect(baseBuildNumber('2015'), 15);
    expect(baseBuildNumber('1015'), 15);
    expect(baseBuildNumber('15'), 15);
  });

  test('e-mail address check before asking Firebase for a link', () {
    expect(EmailLinkAuth.looksLikeEmail('name@gmail.com'), isTrue);
    expect(EmailLinkAuth.looksLikeEmail(' rahim.uddin@yahoo.com '), isTrue);
    expect(EmailLinkAuth.looksLikeEmail('01712345678'), isFalse);
    expect(EmailLinkAuth.looksLikeEmail('name@gmail'), isFalse);
    expect(EmailLinkAuth.looksLikeEmail(''), isFalse);
  });
}
