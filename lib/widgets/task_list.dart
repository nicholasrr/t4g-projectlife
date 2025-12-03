import 'package:flutter/material.dart';
import '../models/task.dart';
import '../db/repositories.dart';
import '../theme.dart';
import '../screens/task_detail_screen.dart';
import '../utils/global_data.dart';

/// The main scrollable list of tasks
class TaskList extends StatelessWidget {
  final String timePeriodId;

  const TaskList({super.key, required this.timePeriodId});

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
            // If showing how-to, render explanatory text instead of tasks
            if (selectedType == SelectedType.howto) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
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
                            'Swipe left or right on a task to complete or delete it.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Otherwise filter tasks by type
            final tasks = TaskRepository().getTasksForPeriod(timePeriodId);
            final filtered =
                tasks
                    .where(
                      (t) =>
                          t.isRecurring ==
                          (selectedType == SelectedType.recurring),
                    )
                    .toList();

            final completedTasks = filtered.where((t) => t.completed).toList();
            final incompleteTasks =
                filtered.where((t) => !t.completed).toList();

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
                            : 'No ad-hoc tasks for this period.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
              slivers: [
                // Incomplete tasks
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _TaskItem(
                      task: incompleteTasks[index],
                      key: ValueKey(incompleteTasks[index].id),
                    ),
                    childCount: incompleteTasks.length,
                  ),
                ),

                // Completed tasks (if any)
                if (completedTasks.isNotEmpty) ...[
                  // "Completed" header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.padding),
                      child: Text(
                        'Completed',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),

                  // Completed task items
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TaskItem(
                        task: completedTasks[index],
                        key: ValueKey(completedTasks[index].id),
                      ),
                      childCount: completedTasks.length,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
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
    final category =
        widget.task.categoryId != null
            ? CategoryRepository().getCategory(widget.task.categoryId!)
            : null;
    final categoryColor =
        category != null ? Color(int.parse(category.colorHex)) : null;

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
        final isDeleteAction =
            dragFlip
                ? direction == DismissDirection.startToEnd
                : direction == DismissDirection.endToStart;

        if (isDeleteAction) {
          // Ask user to confirm deletion
          final confirmed = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
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
          final updatedTask = Task(
            id: widget.task.id,
            title: widget.task.title,
            description: widget.task.description,
            categoryId: widget.task.categoryId,
            completed: !widget.task.completed,
            timePeriodId: widget.task.timePeriodId,
            isRecurring: widget.task.isRecurring,
            cadence: widget.task.timePeriodId[0],
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
              builder:
                  (_) => TaskDetailScreen(
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
                categoryColor?.withOpacity(widget.task.completed ? 0.3 : 0.5) ??
                theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
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
                          decoration:
                              widget.task.completed
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
                    widget.task.description!,
                    style: theme.textTheme.bodyMedium,
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
