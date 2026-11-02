// Bundles the Hind Siliguri font (Bangla + Latin, SIL Open Font License)
// so the app looks the same as the preview on every phone, even offline.
// Run once from apps/mobile (needs internet):
//
//   dart run tool/get_fonts.dart
//
// Then rebuild the app. Safe to run twice.
import 'dart:io';

const _base = 'https://github.com/google/fonts/raw/main/ofl/hindsiliguri/';
const _files = {
  'HindSiliguri-Regular.ttf': 400,
  'HindSiliguri-Medium.ttf': 500,
  'HindSiliguri-SemiBold.ttf': 600,
  'HindSiliguri-Bold.ttf': 700,
};

Future<void> main() async {
  final dir = Directory('assets/fonts')..createSync(recursive: true);
  final client = HttpClient();
  try {
    for (final name in [..._files.keys, 'OFL.txt']) {
      final target = File('${dir.path}/$name');
      if (target.existsSync() && target.lengthSync() > 1000) {
        stdout.writeln('Already have $name');
        continue;
      }
      stdout.writeln('Downloading $name ...');
      final request = await client.getUrl(Uri.parse('$_base$name'));
      final response = await request.close();
      if (response.statusCode != 200) {
        stderr.writeln('Could not download $name (HTTP ${response.statusCode}). Nothing was changed.');
        exitCode = 1;
        return;
      }
      await response.pipe(target.openWrite());
    }
  } on SocketException {
    stderr.writeln('No internet connection. Nothing was changed; the app keeps using the phone fonts.');
    exitCode = 1;
    return;
  } finally {
    client.close();
  }

  final pubspec = File('pubspec.yaml');
  var text = pubspec.readAsStringSync();
  if (text.contains('\n  fonts:\n    - family: Hind Siliguri')) {
    stdout.writeln('pubspec.yaml already lists the font.');
  } else {
    final start = text.indexOf('  # Optional: bundle a Bangla font');
    final block = StringBuffer('  # Hind Siliguri, bundled by tool/get_fonts.dart (SIL Open Font License, see assets/fonts/OFL.txt)\n'
        '  fonts:\n    - family: Hind Siliguri\n      fonts:\n');
    _files.forEach((file, weight) {
      block.write('        - asset: assets/fonts/$file\n');
      if (weight != 400) block.write('          weight: $weight\n');
    });
    text = start >= 0 ? text.substring(0, start) + block.toString() : '$text\n$block';
    pubspec.writeAsStringSync(text);
    stdout.writeln('pubspec.yaml: font added.');
  }
  stdout.writeln('\nDone. Run: flutter pub get, then flutter run');
}
