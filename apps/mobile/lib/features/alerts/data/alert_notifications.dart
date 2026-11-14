import 'dart:async';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/app/router.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/features/alerts/data/alerts_repository.dart';
import 'package:joruri_bd/features/settings/presentation/settings_controller.dart';

/// Phone notifications for disaster alerts.
///
/// Most arrive as push messages from the alert watcher (tools/alerts), sent
/// to FCM topics: `alerts-<bn|en>-<district>`, or `alerts-<bn|en>-all` for a
/// phone that follows the whole country. Android shows those itself, even
/// when the app is closed. While the app is open, it also notifies from the
/// live alert list (which also carries alerts the phone read from BMD/USGS
/// itself), never twice for the same alert.
class AlertNotifications {
  AlertNotifications(this._ref);

  final Ref _ref;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _started = false;
  bool _syncing = false;
  bool _syncAgain = false;

  static const urgentChannel = AndroidNotificationChannel(
    'alerts_urgent',
    'Danger warnings / বিপদ সংকেত',
    description: 'Cyclone danger signals, strong earthquakes and other warnings for your area.',
    importance: Importance.max,
  );
  static const alertChannel = AndroidNotificationChannel(
    'alerts',
    'Disaster alerts / দুর্যোগ সতর্কতা',
    description: 'Weather warnings and earthquake reports for your area.',
    importance: Importance.high,
  );

  static const _notifiedKey = 'alerts.notified';
  static const _topicsKey = 'alerts.topics';
  static const _askedKey = 'alerts.permissionAsked';

  /// Notify only for alerts this fresh; older ones are on the alert screen.
  static const freshness = Duration(hours: 12);

  Future<void> start() async {
    if (_started || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _started = true;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_alert')),
        onDidReceiveNotificationResponse: (r) => _open(r.payload),
      );
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(urgentChannel);
      await android?.createNotificationChannel(alertChannel);
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) _open(launch!.notificationResponse?.payload);
    } catch (e, s) {
      AppLogger.error('Local notifications unavailable', e, s);
    }

    // New alerts in the live list while the app is open.
    _ref.listen<List<HazardAlert>>(activeAlertsProvider, (_, next) => _notifyNew(next), fireImmediately: true);
    // A newly chosen district may already have a warning.
    _ref.listen<String?>(alertDistrictProvider, (_, __) => _notifyNew(_ref.read(activeAlertsProvider)));

    if (!await _ref.read(firebaseReadyProvider.future)) return;
    try {
      FirebaseMessaging.onMessage.listen((m) {
        // Android does not show push messages while the app is open: show it here.
        final id = m.data['alertId'] as String?;
        final n = m.notification;
        if (id == null || n == null || _alreadyNotified(id)) return;
        _markNotified(id);
        _show(id, n.title ?? '', n.body ?? '', urgent: m.notification?.android?.channelId == urgentChannel.id,
            route: m.data['route'] as String?);
      });
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data['route'] as String?));
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _open(initial.data['route'] as String?);
    } catch (e, s) {
      AppLogger.error('Push messages unavailable', e, s);
    }
    // Follow the settings: district, whole country, on/off, language.
    _ref.listen(alertSettingsProvider, (_, __) => syncTopics());
    _ref.listen(alertDistrictProvider, (_, __) => syncTopics());
    _ref.listen(settingsProvider.select((s) => s.languageCode), (_, __) => syncTopics());
    await syncTopics();
  }

  /// Asks for permission to show notifications (Android 13+), once.
  Future<bool> askPermissionOnce() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    if (prefs.getBool(_askedKey) == true) return enabled();
    await prefs.setBool(_askedKey, true);
    return requestPermission();
  }

  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> enabled() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Subscribes to the topics for the current settings and leaves the others.
  Future<void> syncTopics() async {
    if (_syncing) {
      // Settings changed while a sync runs: sync again when it finishes.
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _syncAgain = false;
        await _syncTopicsOnce();
      } while (_syncAgain);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncTopicsOnce() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final settings = _ref.read(alertSettingsProvider);
    final district = _ref.read(alertDistrictProvider);
    final lang = _language();
    final want = <String>{
      if (settings.notify && settings.everywhere) 'alerts-$lang-all',
      if (settings.notify && !settings.everywhere && district != null) 'alerts-$lang-$district',
    };
    final have = {...?prefs.getStringList(_topicsKey)};
    final fcm = FirebaseMessaging.instance;
    try {
      // Saved after every step, so a failure halfway is finished next time.
      for (final t in have.difference(want)) {
        await fcm.unsubscribeFromTopic(t).timeout(const Duration(seconds: 20));
        have.remove(t);
        await prefs.setStringList(_topicsKey, have.toList());
      }
      for (final t in want.difference(have)) {
        await fcm.subscribeToTopic(t).timeout(const Duration(seconds: 20));
        have.add(t);
        await prefs.setStringList(_topicsKey, have.toList());
      }
      AppLogger.info('Alert topics: $want');
    } catch (e, s) {
      // Offline: tried again on the next start or settings change.
      AppLogger.error('Alert topics not updated', e, s);
    }
  }

  String _language() {
    final chosen = _ref.read(settingsProvider).languageCode;
    if (chosen == 'bn' || chosen == 'en') return chosen!;
    return PlatformDispatcher.instance.locale.languageCode == 'en' ? 'en' : 'bn';
  }

  void _notifyNew(List<HazardAlert> alerts) {
    // In the background, Android shows the push message; avoid a second sound.
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
    final settings = _ref.read(alertSettingsProvider);
    if (!settings.notify) return;
    final district = _ref.read(alertDistrictProvider);
    final now = DateTime.now().toUtc();
    final lang = _language();
    for (final a in alerts) {
      if (_alreadyNotified(a.id)) continue;
      if (!a.shouldNotify(districtId: district, everywhere: settings.everywhere)) continue;
      if (now.difference(a.sent) > (a.hazard == Hazard.earthquake ? const Duration(hours: 3) : freshness)) continue;
      _markNotified(a.id);
      final text = a.instruction.isEmpty ? a.description : a.instruction;
      _show(a.id, '${levelWord(a.level, lang == 'bn')}: ${a.headline.resolve(lang)}', text.resolve(lang),
          urgent: a.level.index >= AlertLevel.warning.index, route: '/alerts/${Uri.encodeComponent(a.id)}');
    }
  }

  bool _alreadyNotified(String id) =>
      _ref.read(sharedPreferencesProvider).getStringList(_notifiedKey)?.contains(id) ?? false;

  void _markNotified(String id) {
    final prefs = _ref.read(sharedPreferencesProvider);
    final list = [...?prefs.getStringList(_notifiedKey), id];
    // Remember the last 200 alerts only.
    prefs.setStringList(_notifiedKey, list.length > 200 ? list.sublist(list.length - 200) : list);
  }

  Future<void> _show(String id, String title, String body, {required bool urgent, String? route}) async {
    final channel = urgent ? urgentChannel : alertChannel;
    try {
      await _plugin.show(
        // Same tag as the push message, so Android shows one notification.
        id: 0,
        title: title,
        body: body,
        payload: route,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: channel.importance,
            priority: Priority.max,
            tag: id,
            icon: 'ic_stat_alert',
            color: urgent ? const Color(0xFFD32F2F) : const Color(0xFFE37400),
            styleInformation: BigTextStyleInformation(body),
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            onlyAlertOnce: true,
          ),
        ),
      );
    } catch (e, s) {
      AppLogger.error('Alert notification failed', e, s);
    }
  }

  void _open(String? route) {
    if (route == null || !route.startsWith('/alerts')) return;
    // Wait for the first frame, so the router exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _ref.read(routerProvider).push(route);
      } catch (e, s) {
        AppLogger.error('Could not open alert', e, s);
      }
    });
  }
}

/// "Warning", "সতর্কবার্তা" … for a notification title.
String levelWord(AlertLevel l, bool bn) => switch (l) {
      AlertLevel.emergency => bn ? 'জরুরি বিপদ' : 'EMERGENCY',
      AlertLevel.warning => bn ? 'সতর্কবার্তা' : 'Warning',
      AlertLevel.watch => bn ? 'সতর্ক থাকুন' : 'Be alert',
      AlertLevel.advisory => bn ? 'তথ্য' : 'Advisory',
    };

final alertNotificationsProvider = Provider<AlertNotifications>((ref) => AlertNotifications(ref));
