import 'package:flutter/material.dart';
import '../models/task.dart';
import '../db/repositories.dart';
import '../theme.dart';
import '../utils/utils.dart';
import '../utils/global_data.dart';

/// Simple task detail / creation screen.
/// Creates a new Task for the provided initialTimePeriodId.
class TaskDetailScreen extends StatefulWidget {
  final String initialTimePeriodId;
  final Task? existingTask;

  const TaskDetailScreen({
    super.key,
    required this.initialTimePeriodId,
    this.existingTask,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isRecurring = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // If editing an existing task, prefill fields from it; otherwise use
    // the selected type to determine the default recurring state.
    final existing = widget.existingTask;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description ?? '';
      _isRecurring = existing.isRecurring;
    } else {
      _isRecurring =
          Globals.selectedTypeNotifier.value == SelectedType.recurring;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    setState(() => _saving = true);
    final existing = widget.existingTask;
    if (existing != null) {
      final updated = existing.copyWith(
        title: title,
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        isRecurring: _isRecurring,
      );
      await TaskRepository().editTask(updated);
    } else {
      final cadence =
          widget.initialTimePeriodId.isNotEmpty
              ? widget.initialTimePeriodId[0]
              : 'D';
      final task = Task(
        id: generateTaskId(widget.initialTimePeriodId),
        title: title,
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        categoryId: null,
        completed: false,
        cadence: cadence,
        timePeriodId: widget.initialTimePeriodId,
        isRecurring: _isRecurring,
      );

      await TaskRepository().createTask(task);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask != null ? 'Edit Task' : 'New Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saving ? null : _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What do you want to do?',
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional details',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: AppTheme.spacing),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isRecurring,
              title: const Text('Recurring'),
              onChanged: (v) => setState(() => _isRecurring = v ?? false),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(AppTheme.addIcon),
                label: Text(
                  widget.existingTask != null ? 'Save' : 'Create Task',
                ),
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
