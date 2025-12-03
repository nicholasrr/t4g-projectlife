import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/cadence_bar.dart';
import '../widgets/task_list.dart';
import '../widgets/time_period_header.dart';
import '../widgets/type_selector.dart';
import '../widgets/top_bar.dart';
import '../db/repositories.dart';
import '../utils/utils.dart';
import 'task_detail_screen.dart';

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
    // Try to get the last selected cadence from settings, use 'D'ay if none
    var cadence = _settings.getSelectedTimeCadence() ?? 'D';
    _selectedPeriodId = getCurrentTimePeriodId(cadence);
    _handlePeriodChange(getCurrentTimePeriodId(cadence));
  }

  void _handlePeriodChange(String newPeriodId) {
    if (!isBComparableAndGreaterThanA(_selectedPeriodId, newPeriodId)) {
      // Do not backfill if moving to the future, it will happen naturally ;)
      _backfillPeriod(newPeriodId, false);
    }

    setState(() {
      _selectedPeriodId = newPeriodId;
    });
    _settings.setSelectedCadence(extractCadence(newPeriodId));
  }

  Future<void> _backfillPeriod(String periodId, bool skipRecurring) async {
    final tasks = TaskRepository();
    final periods = TimePeriodRepository();

    if (!shouldBackfillPeriod(periodId) || periods.isBackfilled(periodId)) {
      return;
    }

    // First we port the recurring tasks, only from the previous period
    final previousPeriodId = getPreviousTimePeriodId(periodId);
    final previousRecurringTasks =
        tasks
            .getTasksForPeriod(previousPeriodId)
            .where((task) => task.isRecurring)
            .map((task) => portTaskToPeriod(task, periodId))
            .toList();

    // Backfill non-recurring tasks from previous periods
    await _backfillPeriod(previousPeriodId, true);

    // Port over non-recurring incomplete tasks from previous period
    final previousIncompleteTasks =
        tasks
            .getTasksForPeriod(previousPeriodId)
            .where((task) => !task.isRecurring && !task.completed)
            .map((task) => portTaskToPeriod(task, periodId))
            .toList();

    // Complete backfill
    await tasks.createTasks([
      ...previousRecurringTasks,
      ...previousIncompleteTasks,
    ]);
    await periods.markAsBackfilled(periodId);
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
              child: const TopBar(),
            ),

            // Time period navigator
            SizedBox(
              height: availableHeight * AppTheme.buttonHeightRatio,
              child: TimePeriodHeader(
                selectedPeriodId: _selectedPeriodId,
                onPeriodChanged: _handlePeriodChange,
              ),
            ),

            // Task list (scrollable)
            Expanded(child: TaskList(timePeriodId: _selectedPeriodId)),

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
                        builder:
                            (_) => TaskDetailScreen(
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
                onPeriodChanged: _handlePeriodChange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
