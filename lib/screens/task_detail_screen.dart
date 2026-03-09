import 'package:flutter/material.dart';
import '../models/task.dart';
import '../db/repositories.dart';
import '../db/category_repository.dart';
import '../models/category.dart';
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
  final _targetCountController = TextEditingController();
  bool _isRecurring = false;
  bool _saving = false;
  List<Category> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTask;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description ?? '';
      _isRecurring = existing.isRecurring;
      _selectedCategoryId = existing.categoryId;
      _targetCountController.text = existing.targetCount.toString();
    } else {
      _isRecurring =
          Globals.selectedTypeNotifier.value == SelectedType.recurring;
      _targetCountController.text = '1';
    }
    _loadCategories();
  }

  void _loadCategories() {
    final cats = CategoryRepository().getAllCategories();
    setState(() => _categories = cats);
  }

  Future<void> _showCreateCategoryDialog() async {
    final titleController = TextEditingController();
    String selectedColor = '0xFF90CAF9';

    await showDialog<void>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('New category'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final hex in [
                            '0xFFEF9A9A',
                            '0xFFF48FB1',
                            '0xFFCE93D8',
                            '0xFF9FA8DA',
                            '0xFF90CAF9',
                            '0xFF80DEEA',
                            '0xFFA5D6A7',
                            '0xFFFFF59D',
                            '0xFFFFE082',
                          ])
                            GestureDetector(
                              onTap: () => setState(() => selectedColor = hex),
                              child: Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(int.parse(hex)),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color:
                                        selectedColor == hex
                                            ? Colors.black
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;
                        final id =
                            DateTime.now().microsecondsSinceEpoch.toString();
                        final cat = Category(
                          id: id,
                          title: title,
                          colorHex: selectedColor,
                        );
                        await CategoryRepository().createCategory(cat);
                        _loadCategories();
                        setState(() => _selectedCategoryId = id);
                        Navigator.pop(context);
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetCountController.dispose();
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

    final targetCount = int.tryParse(_targetCountController.text) ?? 1;
    if (targetCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target count must be at least 1')),
      );
      return;
    }

    setState(() => _saving = true);
    final existing = widget.existingTask;
    if (existing != null) {
      final updated = existing.copyWith(
        title: title,
        description: _descriptionController.text.trim(),
        isRecurring: _isRecurring,
        categoryId: _selectedCategoryId,
        targetCount: targetCount,
      );
      await TaskRepository().editTask(updated);
    } else {
      final String targetPeriod;
      final String cadence;
      if (widget.initialTimePeriodId.isNotEmpty &&
          widget.initialTimePeriodId != 'A') {
        // If initial period provided (and not 'All'), use it
        targetPeriod = widget.initialTimePeriodId;
        cadence = widget.initialTimePeriodId[0];
      } else {
        // Save to the day if the target period is not specified
        targetPeriod = getCurrentTimePeriodId('D');
        cadence = 'D';
      }
      final task = Task(
        id: generateTaskId(widget.initialTimePeriodId),
        title: title,
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        completed: false,
        cadence: cadence,
        timePeriodId: targetPeriod,
        isRecurring: _isRecurring,
        targetCount: targetCount,
        recurrenceId: generateId(),
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
            TextField(
              controller: _targetCountController,
              decoration: const InputDecoration(
                labelText: 'Target Count',
                hintText: 'How many times to complete (default: 1)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTheme.spacing),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isRecurring,
              title: const Text('Recurring'),
              onChanged: (v) => setState(() => _isRecurring = v ?? false),
            ),
            const SizedBox(height: AppTheme.spacing),
            // Category selector + create new
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items:
                        _categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(c.colorHex)),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    Text(c.title),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _showCreateCategoryDialog,
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('New'),
                ),
              ],
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
