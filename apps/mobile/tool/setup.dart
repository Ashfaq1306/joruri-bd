// One-time platform setup. Run from apps/mobile AFTER `flutter create`:
//
//   dart run tool/setup.dart
//
// Adds the permissions and settings JORURI BD needs to the Android manifest,
// the Android Gradle file and the iOS Info.plist. Safe to run twice.
import 'dart:io';

const _marker = 'joruri-setup';

void main() {
  _androidManifest();
  _androidGradle();
  _iosInfoPlist();
  stdout.writeln('\nDone. Next: flutter pub get, then flutter run');
}

void _androidManifest() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln('Android manifest not found. Run flutter create first (see README).');
    exitCode = 1;
    return;
  }
  var xml = file.readAsStringSync();
  if (xml.contains(_marker)) {
    stdout.writeln('AndroidManifest.xml: already set up');
    return;
  }

  const permissions = '''
    <!-- $_marker: permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.CALL_PHONE"/>
''';
  xml = xml.replaceFirst('<application', '$permissions    <application');

  // App name shown under the icon.
  xml = xml.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="Joruri BD"');

  // Android 11+ only lets apps open other apps they declare here.
  const intents = '''
        <!-- $_marker: apps we open -->
        <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="sms"/></intent>
        <intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="smsto"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
''';
  if (xml.contains('<queries>')) {
    xml = xml.replaceFirst('<queries>', '<queries>\n$intents');
  } else {
    xml = xml.replaceFirst('</manifest>', '    <queries>\n$intents    </queries>\n</manifest>');
  }

  file.writeAsStringSync(xml);
  stdout.writeln('AndroidManifest.xml: permissions, app name and intents added');
}

void _androidGradle() {
  for (final path in ['android/app/build.gradle.kts', 'android/app/build.gradle']) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final text = file.readAsStringSync();
    final updated = text
        .replaceAll('minSdk = flutter.minSdkVersion', 'minSdk = 26')
        .replaceAll('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 26');
    if (updated != text) {
      file.writeAsStringSync(updated);
      stdout.writeln('$path: minimum Android set to 8.0 (API 26)');
    } else {
      stdout.writeln('$path: check that minSdk is 26 (not changed automatically)');
    }
    return;
  }
}

void _iosInfoPlist() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    stdout.writeln('ios/Runner/Info.plist not found: skipping iOS');
    return;
  }
  var plist = file.readAsStringSync();
  if (plist.contains(_marker)) {
    stdout.writeln('Info.plist: already set up');
    return;
  }

  const additions = '''
	<!-- $_marker -->
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>Joruri BD uses your location only when you press SOS or open My location, to share it with people you choose.</string>
	<key>NSCameraUsageDescription</key>
	<string>Joruri BD uses the camera light as a flashlight. No photos are taken.</string>
	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>tel</string>
		<string>sms</string>
		<string>https</string>
	</array>
	<key>CFBundleLocalizations</key>
	<array>
		<string>bn</string>
		<string>en</string>
	</array>
''';
  final end = plist.lastIndexOf('</dict>');
  plist = plist.replaceRange(end, end, additions);
  plist = plist.replaceFirst(
    RegExp(r'<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>'),
    '<key>CFBundleDisplayName</key>\n\t<string>Joruri BD</string>',
  );
  file.writeAsStringSync(plist);
  stdout.writeln('Info.plist: permission texts, URL schemes and languages added');
}
