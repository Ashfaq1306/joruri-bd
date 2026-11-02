# JORURI BD mobile app

See the main [README](../../README.md) for setup, the release gate and project layout.

Quick start (run in this folder, phone connected by USB):

```bash
flutter create . --org bd.joruri --project-name joruri_bd --platforms android,ios
dart run tool/setup.dart
dart run tool/get_fonts.dart
dart run flutter_launcher_icons
flutter pub get
flutter run --release
```
