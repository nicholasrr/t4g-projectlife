import 'package:flutter/material.dart';
import 'package:projectlife/utils/global_data.dart';
import '../theme.dart';
import '../widgets/cadence_bar.dart';
import '../widgets/task_list.dart';
import '../widgets/time_period_header.dart';
import '../widgets/type_selector.dart';
import '../widgets/top_bar.dart';
import '../db/repositories.dart';
import '../services/notification_service.dart';
import '../utils/utils.dart';
import 'task_detail_screen.dart';
import '../models/task.dart';

/// The main screen of the app, using a vertical layout for all components.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _selectedPeriodId;
  final _settings = SettingsRepository();

  @override
  void initState() {
    super.initState();
    NotificationService.instance.setNavigationCallback(
      _handleNotificationNavigation,
    );
    // Try to get the last selected cadence from settings, use 'D'ay if none
    var cadence = _settings.getSelectedTimeCadence() ?? 'D';
    _selectedPeriodId = getCurrentTimePeriodId(cadence);
    _handlePeriodChange(getCurrentTimePeriodId(cadence), true);
  }

  void _handleNotificationNavigation(String cadence) {
    if (!mounted) return;

    // Pop to the home screen
    Navigator.of(context).popUntil((route) => route.isFirst);
    _handlePeriodChange(getCurrentTimePeriodId(cadence), true);
    Globals.setAll();
  }

  void _handlePeriodChange(String newPeriodId, bool applyBackfill) {
    if (applyBackfill && newPeriodId != 'A') {
      _backfillPeriod(newPeriodId);
    }

    setState(() {
      _selectedPeriodId = newPeriodId;
    });
    _settings.setSelectedCadence(extractCadence(newPeriodId));
  }

  Future<List<Task>> _cleanAndDedupeTasks(List<Task> tasks) async {
    final taskRepository = TaskRepository();
    final Map<String, Task> uniqueTasksByRecurrenceId = {};
    for (final task in tasks) {
      if (task.recurrenceId == null) {
        // No recurrence ID - assign a recurrence ID to it now
        task.recurrenceId = generateId();
        await taskRepository.editTask(task);
      }

      if (!uniqueTasksByRecurrenceId.containsKey(task.recurrenceId!)) {
        uniqueTasksByRecurrenceId[task.recurrenceId!] = task;
      } else {
        final currentTask = uniqueTasksByRecurrenceId[task.recurrenceId!]!;
        if (task.timePeriodId.compareTo(currentTask.timePeriodId) > 0) {
          // This task is from a later time period - replace
          uniqueTasksByRecurrenceId[task.recurrenceId!] = task;
        }
      }
    }
    return uniqueTasksByRecurrenceId.values.toList();
  }

  Future<void> _backfillPeriod(String periodId) async {
    final taskRepository = TaskRepository();
    final periodRepository = TimePeriodRepository();

    if (!shouldBackfillPeriod(periodId) ||
        periodRepository.isBackfilled(periodId)) {
      return;
    }

    final previousPeriodId = getPreviousTimePeriodId(periodId);
    await _backfillPeriod(previousPeriodId);

    final previousRecurringTasks = taskRepository
        .getTasksForPeriod(previousPeriodId)
        .where((task) => task.isRecurring)
        .toList();
    final previousIncompleteTasks = taskRepository
        .getTasksForPeriod(previousPeriodId)
        .where((task) => !task.isRecurring && !task.completed)
        .toList();
    final currentPeriodTasks = await _cleanAndDedupeTasks([
      ...previousRecurringTasks,
      ...previousIncompleteTasks,
      ...taskRepository.getTasksForPeriod(periodId),
    ]);
    final newTasks = currentPeriodTasks
        .where((task) => task.timePeriodId != periodId)
        .map((task) => portTaskToPeriod(task, periodId))
        .toList();

    await taskRepository.createTasks(newTasks);
    await periodRepository.markAsBackfilled(periodId);
  }

  Future<void> _resetBackfill() async {
    final periodRepository = TimePeriodRepository();

    // Reset all backfill flags
    await periodRepository.resetAllBackfillFlags();

    // Trigger backfill for current period
    await _backfillPeriod(_selectedPeriodId);

    // Show feedback to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backfill reset and reapplied'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for proportional sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    final availableHeight = screenHeight - padding.top - padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with engine/settings, period, and filter
            SizedBox(
              height: availableHeight * AppTheme.buttonHeightRatio,
              child: TopBar(
                onReset: () => _handlePeriodChange(
                  getCurrentTimePeriodId(extractCadence(_selectedPeriodId)),
                  false,
                ),
              ),
            ),

            // Time period navigator
            SizedBox(
              height: availableHeight * AppTheme.buttonHeightRatio,
              child: TimePeriodHeader(
                selectedPeriodId: _selectedPeriodId,
                onPeriodChanged: (period) => _handlePeriodChange(period, false),
              ),
            ),

            // Task list (scrollable)
            Expanded(
              child: TaskList(
                timePeriodId: _selectedPeriodId,
                onresetBackfill: _resetBackfill,
              ),
            ),

            // Add task button
            Padding(
              padding: const EdgeInsets.only(
                right: AppTheme.padding,
                bottom: AppTheme.spacing,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: FloatingActionButton(
                  onPressed: () async {
                    // Navigate to the task detail screen to create a new task.
                    // Pass the currently selected period so the new task is created
                    // in the correct time period.
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(
                          initialTimePeriodId: _selectedPeriodId,
                        ),
                      ),
                    );
                    // After returning, rebuild to pick up newly created tasks.
                    setState(() {});
                  },
                  child: const Icon(AppTheme.addIcon),
                ),
              ),
            ),

            // Type selector (Recurring/Ad-hoc/Help)
            SizedBox(
              height: availableHeight * AppTheme.buttonHeightRatio,
              child: const TypeSelector(),
            ),

            // Cadence selector (D/W/M/Q/Y)
            SizedBox(
              height: availableHeight * AppTheme.buttonHeightRatio,
              child: CadenceBar(
                selectedPeriodId: _selectedPeriodId,
                onPeriodChanged: (period) => _handlePeriodChange(period, true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
