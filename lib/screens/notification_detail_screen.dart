import 'package:flutter/material.dart';
import '../db/notification_repository.dart';
import '../models/notification_rule.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../utils/utils.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationRule? existingNotification;

  const NotificationDetailScreen({super.key, this.existingNotification});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final _messageController = TextEditingController();
  final _repo = NotificationRepository();
  late String _selectedPeriodId;
  late TimeOfDay _selectedTime;
  final Set<int> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    final existing = widget.existingNotification;
    _selectedPeriodId = existing?.timePeriodId ?? getCurrentTimePeriodId('D');
    final hour = existing?.hour ?? 9;
    final minute = existing?.minute ?? 0;
    _selectedTime = TimeOfDay(hour: hour, minute: minute);
    _selectedDays.addAll(existing?.daysOfWeek ?? [DateTime.monday]);
    _messageController.text = existing?.message ?? '';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveNotification() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time, weekdays, and message.'),
        ),
      );
      return;
    }

    final rule = NotificationRule(
      id: widget.existingNotification?.id ?? generateId(),
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      daysOfWeek: _selectedDays.toList()..sort(),
      message: message,
      timePeriodId: _selectedPeriodId,
      enabled: true,
    );

    if (widget.existingNotification == null) {
      await _repo.createNotificationRule(rule);
    } else {
      await _repo.editNotificationRule(rule);
    }

    await NotificationService.instance.scheduleNotificationRule(rule);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodOptions = {
      'D': getCurrentTimePeriodId('D'),
      'W': getCurrentTimePeriodId('W'),
      'M': getCurrentTimePeriodId('M'),
      'Q': getCurrentTimePeriodId('Q'),
      'Y': getCurrentTimePeriodId('Y'),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingNotification == null
              ? 'New notification'
              : 'Edit notification',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNotification,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: ListView(
          children: [
            TextButton(
              onPressed: _pickTime,
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacing,
                  horizontal: AppTheme.padding,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Time of day'),
                  Text(_selectedTime.format(context)),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            Text('Weekdays', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacing / 2),
            Wrap(
              spacing: AppTheme.spacing,
              runSpacing: AppTheme.spacing / 2,
              children: [
                for (
                  var weekday = DateTime.monday;
                  weekday <= DateTime.sunday;
                  weekday++
                )
                  FilterChip(
                    label: Text(
                      [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ][weekday - 1],
                    ),
                    selected: _selectedDays.contains(weekday),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(weekday);
                        } else {
                          _selectedDays.remove(weekday);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            DropdownButtonFormField<String>(
              value: _selectedPeriodId,
              decoration: const InputDecoration(
                labelText: 'Time period to open',
              ),
              items:
                  periodOptions.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.value,
                          child: Text(
                            '${entry.key} — ${getPeriodDisplayString(entry.value)}',
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriodId = value;
                  });
                }
              },
            ),
            const SizedBox(height: AppTheme.spacing),
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notification text',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppTheme.spacing * 2),
            ElevatedButton(
              onPressed: _saveNotification,
              child: const Text('Save notification'),
            ),
          ],
        ),
      ),
    );
  }
}
