import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';
import 'theme.dart';
import 'voice_recorder_dialog.dart';
import 'voice_note_player.dart';

class AddTaskDialog extends StatefulWidget {
  final Task? editTask;

  const AddTaskDialog({super.key, this.editTask});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'assignment';
  String _selectedPriority = 'medium';
  String _estimatedDuration = '1h';
  DateTime? _deadline;
  List<VoiceNote> _voiceNotes = [];
  bool _isImportant = false;
  List<DateTime> _reminders = [];

  final List<String> _taskTypes = ['assignment', 'exam', 'note'];
  final List<String> _priorities = ['low', 'medium', 'high'];
  final List<String> _durations = ['30m', '1h', '2h', '3h', '4h', '6h', '8h', '12h'];

  @override
  void initState() {
    super.initState();
    if (widget.editTask != null) {
      _titleController.text = widget.editTask!.title;
      _subjectController.text = widget.editTask!.subject;
      _notesController.text = widget.editTask!.notes ?? '';
      _selectedType = widget.editTask!.type;
      _selectedPriority = widget.editTask!.priority;
      _estimatedDuration = widget.editTask!.estimatedDuration;
      _deadline = widget.editTask!.deadline;
      _voiceNotes = List.from(widget.editTask!.voiceNotes);
      _isImportant = widget.editTask!.isImportant;
      _reminders = List.from(widget.editTask!.reminders);
    } else {
      _deadline = DateTime.now().add(const Duration(days: 7));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline!,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline!),
      );

      if (time != null) {
        setState(() {
          _deadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _addReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline!.subtract(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: _deadline!,
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline!.subtract(const Duration(hours: 2))),
      );

      if (time != null) {
        final reminderTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        
        if (reminderTime.isBefore(_deadline!)) {
          setState(() {
            _reminders.add(reminderTime);
            _reminders.sort();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder must be before deadline'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _removeReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
  }

  Future<void> _recordVoiceNote() async {
    final result = await showDialog<VoiceNote>(
      context: context,
      builder: (context) => VoiceRecorderDialog(
        taskId: widget.editTask?.id,
        contextType: 'task',
      ),
    );

    if (result != null) {
      setState(() {
        _voiceNotes.add(result);
      });
    }
  }

  void _removeVoiceNote(int index) {
    setState(() {
      _voiceNotes.removeAt(index);
    });
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);

      if (widget.editTask != null) {
        widget.editTask!.title = _titleController.text;
        widget.editTask!.type = _selectedType;
        widget.editTask!.deadline = _deadline!;
        widget.editTask!.estimatedDuration = _estimatedDuration;
        widget.editTask!.subject = _subjectController.text;
        widget.editTask!.priority = _selectedPriority;
        widget.editTask!.notes = _notesController.text.isEmpty ? null : _notesController.text;
        widget.editTask!.voiceNotes = _voiceNotes;
        widget.editTask!.isImportant = _isImportant;
        widget.editTask!.reminders = _reminders;
        dataProvider.updateTask(widget.editTask!);
      } else {
        final task = Task(
          id: const Uuid().v4(),
          title: _titleController.text,
          type: _selectedType,
          deadline: _deadline!,
          estimatedDuration: _estimatedDuration,
          subject: _subjectController.text,
          priority: _selectedPriority,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          voiceNotes: _voiceNotes,
          isImportant: _isImportant,
          reminders: _reminders,
        );
        dataProvider.addTask(task);
      }

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editTask != null ? 'Task updated!' : 'Task added!'),
          backgroundColor: AppTheme.submissionPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isImportant 
                    ? AppTheme.examAmber.withOpacity(0.1)
                    : Theme.of(context).cardTheme.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.editTask != null ? 'Edit Task' : 'Add Task',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Task Title *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.task_rounded),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Type *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.category_rounded),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        items: _taskTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppTheme.getContextColor(type),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(type.toUpperCase()),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedType = value!),
                      ),
                      const SizedBox(height: 14),
                      
                      // Important toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isImportant 
                                ? AppTheme.examAmber
                                : Theme.of(context).dividerColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: _isImportant ? AppTheme.examAmber : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mark as Important',
                                style: TextStyle(
                                  fontWeight: _isImportant ? FontWeight.w600 : FontWeight.normal,
                                  color: _isImportant ? AppTheme.examAmber : null,
                                ),
                              ),
                            ),
                            Switch(
                              value: _isImportant,
                              onChanged: (value) => setState(() => _isImportant = value),
                              activeColor: AppTheme.examAmber,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      InkWell(
                        onTap: _selectDeadline,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Deadline *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.calendar_today_rounded),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy • h:mm a').format(_deadline!),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // Reminders section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Reminders (${_reminders.length})',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              TextButton.icon(
                                onPressed: _addReminder,
                                icon: const Icon(Icons.add_alert_rounded, size: 18),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                          if (_reminders.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...List.generate(_reminders.length, (index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentClarity.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.accentClarity.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.notifications_rounded, size: 18),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        DateFormat('MMM dd, h:mm a').format(_reminders[index]),
                                        style: const TextStyle(fontFamily: 'monospace'),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeReminder(index),
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: 'Subject/Course *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.book_rounded),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPriority,
                              decoration: InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.only(left: 12, right: 8, top: 16, bottom: 16),
                              ),
                              items: _priorities.map((priority) {
                                return DropdownMenuItem(
                                  value: priority,
                                  child: Text(priority.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedPriority = value!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _estimatedDuration,
                              decoration: InputDecoration(
                                labelText: 'Duration',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.only(left: 12, right: 8, top: 16, bottom: 16),
                              ),
                              items: _durations.map((duration) {
                                return DropdownMenuItem(
                                  value: duration,
                                  child: Text(duration),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _estimatedDuration = value!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.note_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // Voice notes section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _recordVoiceNote,
                            icon: const Icon(Icons.mic_rounded),
                            label: Text('Add Voice Note (${_voiceNotes.length})'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (_voiceNotes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...List.generate(_voiceNotes.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: VoiceNotePlayer(
                                  voiceNote: _voiceNotes[index],
                                  onDelete: () => _removeVoiceNote(index),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _saveTask,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(widget.editTask != null ? 'Update Task' : 'Add Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.submissionPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}