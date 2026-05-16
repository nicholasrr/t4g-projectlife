import 'package:hive/hive.dart';
import '../models/notification_rule.dart';
import 'hive_boxes.dart';
import '../utils/global_data.dart';

class NotificationRepository {
  final Box _notificationRulesBox;

  NotificationRepository()
    : _notificationRulesBox = Hive.box(notificationRulesBoxName);

  List<NotificationRule> getAllNotificationRules() {
    return _notificationRulesBox.values.cast<NotificationRule>().toList();
  }

  NotificationRule? getNotificationRule(String id) {
    return _notificationRulesBox.get(id) as NotificationRule?;
  }

  Future<void> createNotificationRule(NotificationRule rule) async {
    await _notificationRulesBox.put(rule.id, rule);
    Globals.notificationsVersion.value++;
  }

  Future<void> editNotificationRule(NotificationRule rule) async {
    if (!_notificationRulesBox.containsKey(rule.id)) {
      throw StateError(
        'Cannot edit non-existent notification rule: ${rule.id}',
      );
    }
    await _notificationRulesBox.put(rule.id, rule);
    Globals.notificationsVersion.value++;
  }

  Future<void> deleteNotificationRule(String id) async {
    await _notificationRulesBox.delete(id);
    Globals.notificationsVersion.value++;
  }
}
