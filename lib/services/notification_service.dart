import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../db/notification_repository.dart';
import '../models/notification_rule.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionGranted = false;
  String? _pendingPayload;
  void Function(String)? _navigationCallback;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // Initialize timezone database and set local zone via flutter_timezone.
    tzdata.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // If we cannot obtain the IANA zone, fall back to UTC. Notifications
      // will still be scheduled but may not preserve local wall-clock
      // semantics across device timezone changes until the app is opened.
      tz.setLocalLocation(tz.UTC);
    }

    final androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iOSSettings),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      final payload = details.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _pendingPayload = payload;
      }
    }

    _permissionGranted = await _checkPermissionStatus();
    if (_permissionGranted) {
      await scheduleAllStoredNotifications();
    }

    _initialized = true;
  }

  Future<bool> _checkPermissionStatus() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  Future<bool> checkPermissionStatus() async {
    _permissionGranted = await _checkPermissionStatus();
    return _permissionGranted;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    _permissionGranted = status.isGranted || status.isLimited;
    if (_permissionGranted) {
      await scheduleAllStoredNotifications();
    }
    return _permissionGranted;
  }

  bool get hasPermission => _permissionGranted;

  Future<void> setNavigationCallback(void Function(String) callback) async {
    _navigationCallback = callback;
    if (_pendingPayload != null) {
      callback(_pendingPayload!);
      _pendingPayload = null;
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      if (_navigationCallback != null) {
        _navigationCallback!(payload);
      } else {
        _pendingPayload = payload;
      }
    }
  }

  int _notificationId(String ruleId, int weekday) {
    var hash = 0;
    for (var code in ruleId.codeUnits) {
      hash = ((hash << 5) - hash) + code;
      hash &= 0x7fffffff;
    }
    return hash * 10 + weekday;
  }

  NotificationDetails _notificationDetails() {
    final androidDetails = AndroidNotificationDetails(
      'project_life_notifications',
      'Project Life Notifications',
      channelDescription: 'Scheduled reminders created inside Project: Life',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  Future<void> scheduleNotificationRule(NotificationRule rule) async {
    if (!_permissionGranted || !rule.enabled) {
      return;
    }

    await cancelNotificationRule(rule);
    final details = _notificationDetails();

    for (final weekday in rule.daysOfWeek) {
      // Compute next local DateTime for the requested weekday/time.
      final now = DateTime.now();
      var scheduledLocal = DateTime(
        now.year,
        now.month,
        now.day,
        rule.hour,
        rule.minute,
      );
      while (scheduledLocal.weekday != weekday ||
          !scheduledLocal.isAfter(now)) {
        // Can't schedule a notification for the past, so
        // compute next local DateTime for the requested weekday/time.
        scheduledLocal = scheduledLocal.add(const Duration(days: 1));
      }

      final scheduledTz = tz.TZDateTime.from(scheduledLocal, tz.local);

      await _plugin.zonedSchedule(
        _notificationId(rule.id, weekday),
        'Project: Life',
        rule.message,
        scheduledTz,
        details,
        payload: rule.timePeriodId,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelNotificationRule(NotificationRule rule) async {
    for (final weekday in rule.daysOfWeek) {
      await _plugin.cancel(_notificationId(rule.id, weekday));
    }
  }

  Future<void> scheduleAllStoredNotifications() async {
    await _plugin.cancelAll();
    final rules = NotificationRepository().getAllNotificationRules();
    for (final rule in rules) {
      if (rule.enabled) {
        await scheduleNotificationRule(rule);
      }
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
