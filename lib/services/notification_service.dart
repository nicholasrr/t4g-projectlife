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
      // If we cannot obtain the IANA zone, do not set it, use the default value.
      print('Failed to get timezone from flutter_timezone');
    }

    final androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
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
    final notificationStatus = await Permission.notification.status;
    print('Notification permission status: $notificationStatus');
    final notificationGranted =
        notificationStatus.isGranted || notificationStatus.isLimited;
    final scheduleAlarmStatus = await Permission.scheduleExactAlarm.status;
    print('Schedule exact alarm permission status: $scheduleAlarmStatus');
    final scheduleAlarmGranted =
        scheduleAlarmStatus.isGranted || scheduleAlarmStatus.isLimited;
    return notificationGranted && scheduleAlarmGranted;
  }

  Future<bool> checkPermissionStatus() async {
    _permissionGranted = await _checkPermissionStatus();
    return _permissionGranted;
  }

  Future<List<NotificationRule>> getUnscheduledNotificationRules() async {
    return NotificationRepository()
        .getAllNotificationRules()
        .where((rule) => !rule.scheduledSuccessfully && rule.enabled)
        .toList();
  }

  Future<bool> requestPermission() async {
    final notificationStatus = await Permission.notification.request();
    print('Notification permission status after request: $notificationStatus');
    final notificationGranted =
        notificationStatus.isGranted || notificationStatus.isLimited;
    final scheduleAlarmStatus = await Permission.scheduleExactAlarm.request();
    print(
      'Schedule exact alarm permission status after request: $scheduleAlarmStatus',
    );
    final scheduleAlarmGranted =
        scheduleAlarmStatus.isGranted || scheduleAlarmStatus.isLimited;
    _permissionGranted = notificationGranted && scheduleAlarmGranted;
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
    var id = 0;
    for (final code in ruleId.codeUnits) {
      id = ((id * 31) + code) & 0x7fffffff;
    }
    id = ((id << 3) ^ weekday) & 0x7fffffff;
    return id == 0 ? weekday : id;
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

  Future<bool> scheduleNotificationRule(NotificationRule rule) async {
    if (!_permissionGranted || !rule.enabled) {
      rule.scheduledSuccessfully = false;
      await NotificationRepository().editNotificationRule(rule);
      return false;
    }

    var success = true;
    final details = _notificationDetails();

    try {
      await cancelNotificationRule(rule);
      for (final weekday in rule.daysOfWeek) {
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
          scheduledLocal = scheduledLocal.add(const Duration(days: 1));
        }

        final scheduledTz = tz.TZDateTime.from(scheduledLocal, tz.local);
        print(
          'Scheduling notification for rule ${rule.id} on weekday $weekday at local time ${scheduledLocal.toIso8601String()} (tz: ${scheduledTz.toIso8601String()})',
        );

        await _plugin.zonedSchedule(
          id: _notificationId(rule.id, weekday),
          title: 'Project: Life',
          body: rule.message,
          scheduledDate: scheduledTz,
          notificationDetails: details,
          payload: rule.timeCadence,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (error, stackTrace) {
      success = false;
      // ignore: avoid_print
      print('Failed to schedule notification rule ${rule.id}: $error');
      // ignore: avoid_print
      print(stackTrace);
    }

    rule.scheduledSuccessfully = success;
    await NotificationRepository().editNotificationRule(rule);
    return success;
  }

  Future<bool> cancelNotificationRule(NotificationRule rule) async {
    try {
      for (final weekday in rule.daysOfWeek) {
        await _plugin.cancel(id: _notificationId(rule.id, weekday));
        print(
          'Successfully cancelled notification for rule ${rule.id} on weekday $weekday',
        );
      }
      return true;
    } catch (error, stackTrace) {
      // If cancel fails due to invalid saved IDs, refuse to delete the rule
      // until the user can retry or the issue is corrected.
      // ignore: avoid_print
      print('Failed to cancel notification rule ${rule.id}: $error');
      // ignore: avoid_print
      print(stackTrace);
      return false;
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

  Future<bool> sendDummyNotification() async {
    if (!_permissionGranted) {
      return false;
    }

    try {
      final details = _notificationDetails();
      final id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
      final scheduledDate = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(seconds: 10));
      await _plugin.zonedSchedule(
        id: id,
        title: 'Project: Life',
        body: 'Dummy notification test',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print(
        'Sent dummy notification with id $id scheduled for ${scheduledDate.toIso8601String()}',
      );
      return true;
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('Failed to send dummy notification: $error');
      // ignore: avoid_print
      print(stackTrace);
      return false;
    }
  }

  Future<(int, int)> fixUnscheduledNotifications() async {
    _permissionGranted = await _checkPermissionStatus();
    if (!_permissionGranted) {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return (0, 0);
      }
    }

    final rules = (await getUnscheduledNotificationRules());
    var fixedCount = 0;
    var totalUnscheduled = rules.length;
    for (final rule in rules) {
      final success = await scheduleNotificationRule(rule);
      if (success) {
        fixedCount++;
      }
    }
    return (fixedCount, totalUnscheduled);
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
