import 'package:flutter/material.dart';
import '../models/task.dart';
import '../db/repositories.dart';
import '../theme.dart';
import '../screens/task_detail_screen.dart';
import '../screens/manage_categories_screen.dart';
import '../screens/manage_notifications_screen.dart';
import '../utils/global_data.dart';
import '../db/statistics_service.dart';
import '../utils/utils.dart';

/// The main scrollable list of tasks
class TaskList extends StatelessWidget {
  final String timePeriodId;
  final VoidCallback? onresetBackfill;

  const TaskList({super.key, required this.timePeriodId, this.onresetBackfill});

  @override
  Widget build(BuildContext context) {
    // Listen to the selected type notifier so the list rebuilds when the
    // user switches between Recurring / Ad-hoc / How-to.
    return ValueListenableBuilder<SelectedType>(
      valueListenable: Globals.selectedTypeNotifier,
      builder: (_, selectedType, __) {
        // Also listen to tasksVersion so the list refreshes when tasks are
        // created/edited/deleted. Nest the listener to rebuild task loading
        // whenever either selection or the tasksVersion changes.
        return ValueListenableBuilder<int>(
          valueListenable: Globals.tasksVersion,
          builder: (_, __, ___) {
            // Also listen to selected categories to apply category filters
            return ValueListenableBuilder<Set<String>>(
              valueListenable: Globals.selectedCategoryIds,
              builder: (_, selectedCategories, __) {
                // If showing statistics, render recurring task statistics
                if (selectedType == SelectedType.statistics) {
                  final statsService = StatisticsService();
                  final taskRepo = TaskRepository();

                  // Get all overlapping periods
                  final overlappingPeriods = statsService.getOverlappingPeriods(
                    timePeriodId,
                  );

                  // Load all tasks from overlapping periods
                  final allTasksFromPeriods = <Task>[];
                  for (final periodId in overlappingPeriods) {
                    allTasksFromPeriods.addAll(
                      taskRepo.getTasksForPeriod(periodId),
                    );
                  }

                  // Calculate statistics
                  final stats = statsService.calculateStatistics(
                    allTasksFromPeriods,
                  );

                  if (stats.isEmpty) {
                    return CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'No recurring task statistics available for this period.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final stat = stats[index];
                          return _StatisticsItem(stat: stat);
                        }, childCount: stats.length),
                      ),
                    ],
                  );
                }

                // If showing how-to, render explanatory text instead of tasks
                if (selectedType == SelectedType.howto) {
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.padding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How to use Project: Life',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: AppTheme.spacing),
                              Text(
                                'Switch between Recurring and Ad-hoc to view the tasks of each type.\n'
                                'Tap the + button to quickly add a task to the current time period.\n'
                                'Use the time period header to navigate between periods.\n'
                                'Swipe left or right on a task to complete or delete it.\n'
                                'Tap on a task to edit its details.\n'
                                'Use the category filter (top right) to filter tasks by category.\n'
                                'See statistics for recurring tasks of shorter periods by selecting "Statistics".',
                              ),
                              const SizedBox(height: AppTheme.spacing * 1.5),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ManageCategoriesScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Click here to manage categories',
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ManageNotificationsScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Click here to manage notifications',
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text(
                                    'Backfill tasks from previous periods',
                                  ),
                                  onPressed: onresetBackfill != null
                                      ? () {
                                          showDialog<void>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Start backfill?',
                                              ),
                                              content: const Text(
                                                'This will port incomplete or recurring tasks from previous periods.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    onresetBackfill!();
                                                  },
                                                  child: const Text('Reset'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Otherwise filter tasks by type (unless 'all' is selected), then by selected categories (if any)
                final tasks = TaskRepository().getTasksForPeriod(timePeriodId);
                final baseFiltered = (selectedType == SelectedType.all)
                    ? tasks
                    : tasks
                          .where(
                            (t) =>
                                t.isRecurring ==
                                (selectedType == SelectedType.recurring),
                          )
                          .toList();

                final filtered = selectedCategories.isNotEmpty
                    ? baseFiltered.where((t) {
                        final hasCategory = t.categoryId != null;
                        final matchesCategory =
                            hasCategory &&
                            selectedCategories.contains(t.categoryId);
                        final matchesUncategorized =
                            !hasCategory &&
                            selectedCategories.contains(
                              Globals.uncategorizedKey,
                            );
                        return matchesCategory || matchesUncategorized;
                      }).toList()
                    : baseFiltered;

                // Apply sorting
                final sortMode = SettingsRepository().getSortMode();
                final categoryRepo = CategoryRepository();

                void applySorting(List<Task> taskList) {
                  switch (sortMode) {
                    case 'title_asc':
                      taskList.sort(
                        (a, b) => a.title.toLowerCase().compareTo(
                          b.title.toLowerCase(),
                        ),
                      );
                      break;
                    case 'title_desc':
                      taskList.sort(
                        (a, b) => b.title.toLowerCase().compareTo(
                          a.title.toLowerCase(),
                        ),
                      );
                      break;
                    case 'category_asc':
                      taskList.sort((a, b) {
                        final catA = a.categoryId != null
                            ? categoryRepo.getCategory(a.categoryId!)?.title ??
                                  ''
                            : '';
                        final catB = b.categoryId != null
                            ? categoryRepo.getCategory(b.categoryId!)?.title ??
                                  ''
                            : '';
                        return catA.toLowerCase().compareTo(catB.toLowerCase());
                      });
                      break;
                    case 'category_desc':
                      taskList.sort((a, b) {
                        final catA = a.categoryId != null
                            ? categoryRepo.getCategory(a.categoryId!)?.title ??
                                  ''
                            : '';
                        final catB = b.categoryId != null
                            ? categoryRepo.getCategory(b.categoryId!)?.title ??
                                  ''
                            : '';
                        return catB.toLowerCase().compareTo(catA.toLowerCase());
                      });
                      break;
                    case 'none':
                    default:
                      // No sorting
                      break;
                  }
                }

                final completedTasks = filtered
                    .where((t) => t.completed)
                    .toList();
                final incompleteTasks = filtered
                    .where((t) => !t.completed)
                    .toList();

                applySorting(completedTasks);
                applySorting(incompleteTasks);

                // If no tasks available, show an empty state message
                if (filtered.isEmpty) {
                  return CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            selectedType == SelectedType.recurring
                                ? 'No recurring tasks for this period.'
                                : selectedType == SelectedType.adhoc
                                ? 'No ad-hoc tasks for this period.'
                                : 'No tasks for this period.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                List<Widget> slivers = [];
                slivers.addAll(getSlivers(context, incompleteTasks, false));

                // Completed tasks (if any)
                if (completedTasks.isNotEmpty) {
                  // "Completed" header
                  slivers.add(
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.padding),
                        child: Text(
                          'Completed',
                          style: Theme.of(context).textTheme.titleLarge!
                              .copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                        ),
                      ),
                    ),
                  );

                  // Completed task items
                  slivers.addAll(getSlivers(context, completedTasks, true));
                }

                return CustomScrollView(slivers: slivers);
              },
            );
          },
        );
      },
    );
  }

  List<Widget> getSlivers(
    BuildContext context,
    List<Task> tasks,
    bool isCompletedSection,
  ) {
    final List<Widget> slivers = [];
    for (final cadence in ['D', 'W', 'M', 'Q', 'Y']) {
      final cadenceTasks = tasks.where((t) => t.cadence == cadence).toList();
      bool shouldShowCadenceHeader =
          timePeriodId == 'A' &&
          (cadenceTasks.isNotEmpty || !isCompletedSection);
      if (shouldShowCadenceHeader) {
        // Do not show title for completed section if there are no tasks, to avoid cluttering the UI
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.padding),
              child: Text(
                getCadenceTasksDisplayString(cadence),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      }

      if (shouldShowCadenceHeader && cadenceTasks.isEmpty) {
        // If we are showing the title but there are no tasks, show something.
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.padding,
                vertical: AppTheme.spacing / 2,
              ),
              child: Text(
                'No ${getCadenceTasksDisplayString(cadence).toLowerCase()}',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      } else {
        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _TaskItem(
                task: cadenceTasks[index],
                key: ValueKey(cadenceTasks[index].id),
              ),
              childCount: cadenceTasks.length,
            ),
          ),
        );
      }
    }
    return slivers;
  }
}

/// Individual task item with swipe actions
class _TaskItem extends StatefulWidget {
  final Task task;

  const _TaskItem({super.key, required this.task});

  @override
  State<_TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<_TaskItem> {
  final _repositories = TaskRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = widget.task.categoryId != null
        ? CategoryRepository().getCategory(widget.task.categoryId!)
        : null;
    final categoryColor = category != null
        ? Color(int.parse(category.colorHex))
        : null;

    final settings = SettingsRepository();
    final dragFlip = settings.getDragFlip();

    // Define backgrounds based on dragFlip setting
    final completeBackground = Container(
      color: theme.colorScheme.primary,
      alignment: dragFlip ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
      child: Icon(Icons.check, color: theme.colorScheme.onPrimary),
    );

    final deleteBackground = Container(
      color: theme.colorScheme.error,
      alignment: dragFlip ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
      child: Icon(Icons.delete, color: theme.colorScheme.onError),
    );

    return Dismissible(
      key: ValueKey(widget.task.id),
      // Use confirmDismiss so we can ask the user to confirm deletion and
      // handle completion without actually removing the widget from the tree.
      confirmDismiss: (direction) async {
        final settings = SettingsRepository();
        final dragFlip = settings.getDragFlip();
        final isDeleteAction = dragFlip
            ? direction == DismissDirection.startToEnd
            : direction == DismissDirection.endToStart;

        if (isDeleteAction) {
          // Ask user to confirm deletion
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Task?'),
              content: const Text('This action cannot be undone.'),
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
            await _repositories.deleteTask(widget.task.id);
            return true; // allow Dismissible to remove the item
          }
          return false; // cancelled
        } else {
          // Completion action: toggle completed state but do not dismiss the
          // widget (return false so Dismissible keeps it in the tree).
          final updatedTask = widget.task.copyWith(
            completed: !widget.task.completed,
          );
          await _repositories.editTask(updatedTask);
          return false;
        }
      },
      background: dragFlip ? deleteBackground : completeBackground,
      secondaryBackground: dragFlip ? completeBackground : deleteBackground,
      child: InkWell(
        onTap: () async {
          // Open task in edit mode
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(
                initialTimePeriodId: widget.task.timePeriodId,
                existingTask: widget.task,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.padding,
            vertical: AppTheme.spacing / 2,
          ),
          decoration: BoxDecoration(
            color:
                categoryColor?.withValues(
                  alpha: widget.task.completed ? 0.3 : 0.5,
                ) ??
                theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.1),
                blurRadius: AppTheme.radius,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.task.title,
                        style: theme.textTheme.titleMedium!.copyWith(
                          decoration: widget.task.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        widget.task.categoryId != null
                            ? "(${CategoryRepository().getCategory(widget.task.categoryId!)!.title})"
                            : '',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    // Show count display if targetCount > 1
                    if (widget.task.targetCount > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          "${widget.task.currentCount}/${widget.task.targetCount}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    if (widget.task.completed)
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
                if (widget.task.description != null &&
                    widget.task.description!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacing / 2),
                  Text(
                    widget.task.description!
                            .replaceAll('\n', ' ')
                            .substring(
                              0,
                              widget.task.description!.length > 100
                                  ? 100
                                  : widget.task.description!.length,
                            ) +
                        (widget.task.description!.length > 100 ? '...' : ''),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                // Counter buttons if targetCount > 1
                if (widget.task.targetCount > 1 && !widget.task.completed) ...[
                  const SizedBox(height: AppTheme.spacing),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        iconSize: 20,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: widget.task.currentCount > 0
                            ? () async {
                                final updatedTask = widget.task.copyWith(
                                  currentCount: widget.task.currentCount - 1,
                                );
                                await _repositories.editTask(updatedTask);
                              }
                            : null,
                      ),
                      const SizedBox(width: AppTheme.spacing),
                      IconButton(
                        icon: const Icon(Icons.add),
                        iconSize: 20,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed:
                            widget.task.currentCount < widget.task.targetCount
                            ? () async {
                                final newCount = widget.task.currentCount + 1;
                                final isNowComplete =
                                    newCount >= widget.task.targetCount;
                                final updatedTask = widget.task.copyWith(
                                  currentCount: newCount,
                                  completed: isNowComplete,
                                );
                                await _repositories.editTask(updatedTask);
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Statistics item showing recurring task completion stats
class _StatisticsItem extends StatelessWidget {
  final dynamic stat; // TaskStatistics

  const _StatisticsItem({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = stat.completedCount >= stat.expectedCount;
    final completionRate = stat.completionRate;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.padding,
        vertical: AppTheme.spacing / 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: AppTheme.radius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "${stat.taskTitle} (${stat.cadence})",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isComplete)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: AppTheme.spacing),
            // Completion info
            Text(
              '${stat.completedCount}/${stat.expectedCount} completed',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacing / 2),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completionRate / 100,
                minHeight: 8,
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.1,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completionRate >= 100
                      ? theme.colorScheme.primary
                      : completionRate >= 50
                      ? Colors.orange
                      : theme.colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing / 2),
            // Percentage
            Text(
              '${completionRate.toStringAsFixed(1)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
