import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/cadence_bar.dart';
import '../widgets/task_list.dart';
import '../widgets/time_period_header.dart';
import '../widgets/type_selector.dart';
import '../widgets/top_bar.dart';
import '../db/repositories.dart';

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
    _initializeSelectedPeriod();
  }

  void _initializeSelectedPeriod() {
    // Try to get the last selected period from settings
    final savedPeriod = _settings.getSelectedTimePeriodId();
    if (savedPeriod != null) {
      _selectedPeriodId = savedPeriod;
    } else {
      // Default to current day if no saved period
      final now = DateTime.now();
      _selectedPeriodId =
          'D#${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _settings.setSelectedTimePeriodId(_selectedPeriodId);
    }
  }

  Future<void> _backfillPeriod(String periodId) async {
    final tasks = TaskRepository();
    final periods = TimePeriodRepository();

    // Skip if already backfilled
    if (periods.isBackfilled(periodId)) return;

    // Get previous period's tasks
    final previousPeriodId = switch (periodId[0]) {
      'D' => _getPreviousDayId(periodId),
      'W' => _getPreviousWeekId(periodId),
      'M' => _getPreviousMonthId(periodId),
      'Q' => _getPreviousQuarterId(periodId),
      'Y' => _getPreviousYearId(periodId),
      _ => periodId,
    };

    // Port over tasks from previous period
    final previousTasks = tasks.getTasksForPeriod(previousPeriodId);
    final tasksToPort =
        previousTasks
            .where((task) => task.isRecurring || !task.completed)
            .map(
              (task) => task.copyWith(
                id: '${task.id}_${periodId}',
                timePeriodId: periodId,
                completed: false,
              ),
            )
            .toList();

    if (tasksToPort.isNotEmpty) {
      await tasks.createTasks(tasksToPort);
    }

    // Mark as backfilled
    await periods.markAsBackfilled(periodId);
  }

  void _handlePeriodChange(String newPeriodId) {
    // Only backfill when moving forward in time
    if (_comparePeriods(_selectedPeriodId, newPeriodId) < 0) {
      _backfillPeriod(newPeriodId);
    }

    setState(() {
      _selectedPeriodId = newPeriodId;
    });
    _settings.setSelectedTimePeriodId(newPeriodId);
  }

  int _comparePeriods(String a, String b) {
    final partsA = a.split('#')[1].split('-').map(int.parse).toList();
    final partsB = b.split('#')[1].split('-').map(int.parse).toList();

    for (var i = 0; i < partsA.length; i++) {
      if (partsA[i] != partsB[i]) {
        return partsA[i].compareTo(partsB[i]);
      }
    }
    return 0;
  }

  String _getPreviousDayId(String periodId) {
    final parts = periodId.split('#')[1].split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    ).subtract(const Duration(days: 1));
    return 'D#${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getPreviousWeekId(String periodId) {
    final parts = periodId.split('#')[1].split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    ).subtract(const Duration(days: 7));
    return 'W#${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getPreviousMonthId(String periodId) {
    final parts = periodId.split('#')[1].split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) - 1;
    if (month < 1) {
      year--;
      month = 12;
    }
    return 'M#$year-${month.toString().padLeft(2, '0')}';
  }

  String _getPreviousQuarterId(String periodId) {
    final parts = periodId.split('#')[1].split('-');
    var year = int.parse(parts[0]);
    var quarter = int.parse(parts[1]) - 1;
    if (quarter < 1) {
      year--;
      quarter = 4;
    }
    return 'Q#$year-$quarter';
  }

  String _getPreviousYearId(String periodId) {
    final parts = periodId.split('#')[1];
    return 'Y#${int.parse(parts) - 1}';
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for proportional sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    final availableHeight = screenHeight - padding.top - padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
                  onPressed: () {
                    // TODO: Navigate to task detail screen
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
