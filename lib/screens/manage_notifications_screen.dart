import 'package:flutter/material.dart';
import 'package:projectlife/utils/utils.dart';
import '../db/notification_repository.dart';
import '../models/notification_rule.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import 'notification_detail_screen.dart';

class ManageNotificationsScreen extends StatefulWidget {
  const ManageNotificationsScreen({super.key});

  @override
  State<ManageNotificationsScreen> createState() =>
      _ManageNotificationsScreenState();
}

class _ManageNotificationsScreenState extends State<ManageNotificationsScreen> {
  bool _permissionGranted = false;
  List<NotificationRule> _rules = [];
  final _repo = NotificationRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final permissionGranted = await NotificationService.instance
        .checkPermissionStatus();
    if (!permissionGranted) {
      final requested = await NotificationService.instance.requestPermission();
      setState(() {
        _permissionGranted = requested;
      });
    } else {
      setState(() {
        _permissionGranted = true;
      });
    }

    if (_permissionGranted) {
      await _fixUnscheduledNotifications(showResult: false);
    }

    _refreshRules();
  }

  Future<void> _fixUnscheduledNotifications({bool showResult = true}) async {
    final (fixedCount, totalUnscheduled) = await NotificationService.instance
        .fixUnscheduledNotifications();
    _refreshRules();

    final String text;
    if (totalUnscheduled == 0) {
      text = 'No undelivered notifications found.';
    } else if (fixedCount == totalUnscheduled) {
      text = 'All $fixedCount undelivered notification(s) have been fixed.';
    } else {
      text =
          'Fixed $fixedCount out of $totalUnscheduled undelivered notification(s). Please try again or check app permissions.';
    }

    if (showResult && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _refreshRules() {
    setState(() {
      _rules = _repo.getAllNotificationRules();
    });
  }

  Future<void> _deleteRule(NotificationRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notification?'),
        content: const Text(
          'This will remove the scheduled notification permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cancelled = await NotificationService.instance
          .cancelNotificationRule(rule);
      if (!cancelled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to cancel the scheduled notification. Please try again.',
              ),
            ),
          );
        }
        return;
      }
      await _repo.deleteNotificationRule(rule.id);
      _refreshRules();
    }
  }

  Future<void> _sendDummyNotification() async {
    final sent = await NotificationService.instance.sendDummyNotification();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'Dummy notification sent. Check your notification tray in 10 seconds.'
              : 'Unable to send dummy notification. Check permissions.',
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await NotificationService.instance.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyColor = _permissionGranted
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withAlpha(0x7F);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage notifications'),
        actions: [
          if (_permissionGranted)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Retry undelivered notifications',
              onPressed: _fixUnscheduledNotifications,
            ),
          if (_permissionGranted)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New notification',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationDetailScreen(),
                  ),
                );
                _refreshRules();
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: _permissionGranted ? 1 : 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scheduled notifications appear at the selected time and weekday.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: bodyColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing),
                  Text(
                    'Each notification opens the app on the chosen time period when tapped.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: bodyColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing),
                  if (!_permissionGranted) ...[
                    Text(
                      'App not allowed to send notifications. Click here to allow.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing / 2),
                    TextButton(
                      onPressed: _openSettings,
                      child: const Text('Open app settings'),
                    ),
                    const SizedBox(height: AppTheme.spacing),
                  ],
                  if (_permissionGranted) ...[
                    ElevatedButton(
                      onPressed: _fixUnscheduledNotifications,
                      child: const Text(
                        'Click here to fix notification settings',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing),
                    ElevatedButton(
                      onPressed: _sendDummyNotification,
                      child: const Text('Send dummy notification'),
                    ),
                    const SizedBox(height: AppTheme.spacing),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _permissionGranted
                  ? _rules.isEmpty
                        ? Center(
                            child: Text(
                              'No scheduled notifications yet. Tap + to add one.',
                              style: theme.textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: _rules.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final rule = _rules[index];
                              return Dismissible(
                                key: ValueKey(rule.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  await _deleteRule(rule);
                                  return false;
                                },
                                background: Container(
                                  color: theme.colorScheme.error,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.padding,
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(rule.formattedTime),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${rule.abbreviatedDays} • ${getCadenceDisplayString(rule.timeCadence)}',
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        rule.message,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            NotificationDetailScreen(
                                              existingNotification: rule,
                                            ),
                                      ),
                                    );
                                    _refreshRules();
                                  },
                                ),
                              );
                            },
                          )
                  : Center(
                      child: Text(
                        'Notifications are disabled for this app.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: bodyColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
