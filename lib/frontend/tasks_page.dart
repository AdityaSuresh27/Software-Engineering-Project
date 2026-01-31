import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'theme.dart';
import 'add_task_dialog.dart';
import '../backend/data_provider.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String _sortBy = 'deadline';
  
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final tasks = dataProvider.tasks;
        
        return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Events'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'deadline', child: Text('Sort by Deadline')),
              const PopupMenuItem(value: 'subject', child: Text('Sort by Subject')),
              const PopupMenuItem(value: 'priority', child: Text('Sort by Priority')),
              const PopupMenuItem(value: 'type', child: Text('Sort by Type')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 64,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks yet',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first task',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskCard(context, task, dataProvider);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const AddTaskDialog(),
        ),
        backgroundColor: AppTheme.accentFocus,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Task', style: TextStyle(color: Colors.white)),
      ),
    );
      },
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildChip('All', true),
          const SizedBox(width: 8),
          _buildChip('Exams', false),
          const SizedBox(width: 8),
          _buildChip('Assignments', false),
          const SizedBox(width: 8),
          _buildChip('High Priority', false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {},
      selectedColor: AppTheme.accentFocus.withOpacity(0.2),
      checkmarkColor: AppTheme.accentFocus,
      labelStyle: TextStyle(
        color: selected ? AppTheme.accentFocus : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, task, DataProvider dataProvider) {
    final color = AppTheme.getContextColor(task.type);
    final isCompleted = task.completed;
    final daysUntil = task.deadline.difference(DateTime.now()).inDays;
    final deadlineText = daysUntil == 0
        ? 'Today'
        : daysUntil == 1
            ? 'Tomorrow'
            : daysUntil < 0
                ? 'Overdue'
                : '$daysUntil days';
    
    return Slidable(
      key: ValueKey(task.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              dataProvider.toggleTaskComplete(task.id);
            },
            backgroundColor: AppTheme.accentClarity,
            foregroundColor: Colors.white,
            icon: Icons.check_rounded,
            label: 'Done',
            borderRadius: BorderRadius.circular(16),
          ),
          SlidableAction(
            onPressed: (context) {
              // TODO: Implement snooze
            },
            backgroundColor: AppTheme.accentMomentum,
            foregroundColor: Colors.white,
            icon: Icons.schedule_rounded,
            label: 'Snooze',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted 
                ? AppTheme.accentClarity.withOpacity(0.3)
                : color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isCompleted ? AppTheme.accentClarity : color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : _getTaskIcon(task.type),
              color: isCompleted ? AppTheme.accentClarity : color,
            ),
          ),
          title: Text(
            task.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted 
                  ? Theme.of(context).textTheme.bodyMedium?.color
                  : null,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      'Due in $deadlineText',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.timer_outlined, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      task.estimatedDuration,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.subject,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 10,
                            color: _getPriorityColor(task.priority),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getPriorityColor(task.priority),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AddTaskDialog(editTask: task),
            );
          },
        ),
      ),
    );
  }

  IconData _getTaskIcon(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return Icons.quiz_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      case 'note':
        return Icons.description_rounded;
      default:
        return Icons.task_rounded;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.examAmber;
      case 'medium':
        return AppTheme.accentMomentum;
      case 'low':
        return AppTheme.accentClarity;
      default:
        return AppTheme.notesGray;
    }
  }
}