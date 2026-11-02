import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/features/settings/data/settings_repository.dart';
import 'package:joruri_bd/features/settings/domain/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  /// Applies a change at once (the UI updates instantly), then saves it.
  Future<void> change(AppSettings Function(AppSettings current) update) async {
    state = update(state);
    await ref.read(settingsRepositoryProvider).save(state);
  }
}
