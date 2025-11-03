import 'package:flutter/material.dart';
import '../models/task.dart';
import '../db/repositories.dart';
import '../theme.dart';

/// The main scrollable list of tasks
class TaskList extends StatelessWidget {
  final String timePeriodId;

  const TaskList({super.key, required this.timePeriodId});

  @override
  Widget build(BuildContext context) {
    final tasks = TaskRepository().getTasksForPeriod(timePeriodId);
    final completedTasks = tasks.where((t) => t.completed).toList();
    final incompleteTasks = tasks.where((t) => !t.completed).toList();

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

  void _onDismissed(DismissDirection direction) {
    final settings = SettingsRepository();
    final dragFlip = settings.getDragFlip();
    final isDeleteAction =
        dragFlip
            ? direction == DismissDirection.startToEnd
            : direction == DismissDirection.endToStart;

    if (isDeleteAction) {
      // Delete task
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Delete Task?'),
              content: const Text('This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _repositories.deleteTask(widget.task.id);
                    Navigator.pop(context);
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
      );
    } else {
      // Toggle completion
      final updatedTask = Task(
        id: widget.task.id,
        title: widget.task.title,
        description: widget.task.description,
        categoryId: widget.task.categoryId,
        completed: !widget.task.completed,
        timePeriodId: widget.task.timePeriodId,
        isRecurring: widget.task.isRecurring,
        cadence:
            widget.task.timePeriodId[0], // Extract D/W/M/Q/Y from timePeriodId
      );
      _repositories.editTask(updatedTask);
    }
  }

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
      onDismissed: _onDismissed,
      background: dragFlip ? deleteBackground : completeBackground,
      secondaryBackground: dragFlip ? completeBackground : deleteBackground,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.padding,
          vertical: AppTheme.spacing / 2,
        ),
        decoration: BoxDecoration(
          color:
              categoryColor?.withOpacity(widget.task.completed ? 0.3 : 1) ??
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
                  if (widget.task.completed)
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
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
    );
  }
}
