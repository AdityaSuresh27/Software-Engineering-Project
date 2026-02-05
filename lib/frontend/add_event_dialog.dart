// add_event_dialog.dart - REDESIGNED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';
import 'theme.dart';
import 'voice_recorder_dialog.dart';
import 'voice_note_player.dart';

class AddEventDialog extends StatefulWidget {
  final DateTime? selectedDate;
  final Event? editEvent;
  final String? presetClassification;

  const AddEventDialog({
    super.key,
    this.selectedDate,
    this.editEvent,
    this.presetClassification,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  late TabController _tabController;

  String _selectedClassification = 'class';
  String? _selectedCategory;
  String _selectedPriority = 'medium';
  String _estimatedDuration = '1h';
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isAllDay = false;
  bool _isCompleted = false;
  bool _isImportant = false;
  List<VoiceNote> _voiceNotes = [];
  List<DateTime> _reminders = [];
  String? _customColor;

  final List<String> _classifications = [
    'class',
    'exam',
    'assignment',
    'meeting',
    'personal',
    'other'
  ];

  final List<String> _priorities = ['low', 'medium', 'high', 'critical'];
  final List<String> _durations = [
    '15m',
    '30m',
    '1h',
    '2h',
    '3h',
    '4h',
    '6h',
    '8h'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.presetClassification != null) {
      _selectedClassification = widget.presetClassification!;
    }

    if (widget.editEvent != null) {
      _titleController.text = widget.editEvent!.title;
      _locationController.text = widget.editEvent!.location ?? '';
      _notesController.text = widget.editEvent!.notes ?? '';
      _selectedClassification = widget.editEvent!.classification;
      _selectedCategory = widget.editEvent!.category;
      _selectedPriority = widget.editEvent!.priority;
      _estimatedDuration = widget.editEvent!.estimatedDuration ?? '1h';
      _startTime = widget.editEvent!.startTime;
      _endTime = widget.editEvent!.endTime;
      _isAllDay = widget.editEvent!.isAllDay;
      _isCompleted = widget.editEvent!.isCompleted;
      _isImportant = widget.editEvent!.isImportant;
      _voiceNotes = List.from(widget.editEvent!.voiceNotes);
      _reminders = List.from(widget.editEvent!.reminders);
      _customColor = widget.editEvent!.color;
    } else {
      _startTime = widget.selectedDate ?? DateTime.now();
      _endTime = _startTime!.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool get _isTaskType =>
      _selectedClassification == 'assignment' ||
      _selectedClassification == 'exam';

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    final color = AppTheme.getClassificationColor(_selectedClassification);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 16),
      prefixIcon: Icon(icon, color: color),
      filled: true,
      fillColor: color.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: color,
          width: 2.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );
  }

  Future<void> _selectDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime! : (_endTime ?? _startTime!),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null && !_isAllDay) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            isStart ? _startTime! : (_endTime ?? _startTime!)),
      );

      if (time != null) {
        setState(() {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          if (isStart) {
            _startTime = newDateTime;
            if (_endTime != null && _endTime!.isBefore(_startTime!)) {
              _endTime = _startTime!.add(const Duration(hours: 1));
            }
          } else {
            _endTime = newDateTime;
          }
        });
      }
    } else if (date != null) {
      setState(() {
        if (isStart) {
          _startTime = DateTime(date.year, date.month, date.day);
        } else {
          _endTime = DateTime(date.year, date.month, date.day, 23, 59);
        }
      });
    }
  }

  Future<void> _addReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime!.subtract(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: _startTime!,
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _startTime!.subtract(const Duration(hours: 1))),
      );

      if (time != null) {
        final reminderTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        if (reminderTime.isBefore(_startTime!)) {
          setState(() {
            _reminders.add(reminderTime);
            _reminders.sort();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Reminder must be before event start time'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
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
        eventId: widget.editEvent?.id,
        contextType: 'event',
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

void _saveEvent() {
  // Remove form validation dependency - allow saving from any tab
  if (_titleController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Event title is required'),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Switch to details tab to show the error
    _tabController.animateTo(0);
    return;
  }

  final dataProvider = Provider.of<DataProvider>(context, listen: false);

  if (widget.editEvent != null) {
    widget.editEvent!.title = _titleController.text;
    widget.editEvent!.classification = _selectedClassification;
    widget.editEvent!.category = _selectedCategory;
    widget.editEvent!.startTime = _startTime!;
    widget.editEvent!.endTime = _isTaskType ? null : _endTime;
    widget.editEvent!.location =
        _locationController.text.isEmpty ? null : _locationController.text;
    widget.editEvent!.notes =
        _notesController.text.isEmpty ? null : _notesController.text;
    widget.editEvent!.priority = _selectedPriority;
    widget.editEvent!.estimatedDuration =
        _isTaskType ? _estimatedDuration : null;
    widget.editEvent!.isAllDay = _isAllDay;
    widget.editEvent!.isCompleted = _isCompleted;
    widget.editEvent!.isImportant = _isImportant;
    widget.editEvent!.voiceNotes = _voiceNotes;
    widget.editEvent!.reminders = _reminders;
    widget.editEvent!.color = _customColor;
    dataProvider.updateEvent(widget.editEvent!);
  } else {
    final event = Event(
      id: const Uuid().v4(),
      title: _titleController.text,
      classification: _selectedClassification,
      category: _selectedCategory,
      startTime: _startTime!,
      endTime: _isTaskType ? null : _endTime,
      location: _locationController.text.isEmpty
          ? null
          : _locationController.text,
      notes:
          _notesController.text.isEmpty ? null : _notesController.text,
      priority: _selectedPriority,
      estimatedDuration: _isTaskType ? _estimatedDuration : null,
      isAllDay: _isAllDay,
      isCompleted: _isCompleted,
      isImportant: _isImportant,
      voiceNotes: _voiceNotes,
      reminders: _reminders,
      color: _customColor,
    );
    dataProvider.addEvent(event);
  }

  Navigator.pop(context);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
          widget.editEvent != null ? 'Event updated' : 'Event created'),
      backgroundColor: AppTheme.successGreen,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final color = AppTheme.getClassificationColor(_selectedClassification);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      AppTheme.getClassificationIcon(_selectedClassification),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.editEvent != null
                              ? 'Edit Event'
                              : 'Create Event',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedClassification[0].toUpperCase() +
                              _selectedClassification.substring(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(  // Added "child:" here
                controller: _tabController,
                labelColor: color,
                unselectedLabelColor:
                    Theme.of(context).textTheme.bodyMedium?.color,
                indicatorColor: color,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: const [
                  Tab(text: 'Details'),
                  Tab(text: 'Advanced'),
                  Tab(text: 'Notes'),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(dataProvider),
                  _buildAdvancedTab(),
                  _buildAttachmentsTab(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                border: Border(
                  top: BorderSide(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saveEvent,
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(
                    widget.editEvent != null ? 'Update Event' : 'Create Event',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(DataProvider dataProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              style: const TextStyle(fontSize: 17),
              decoration: _buildInputDecoration('Event Title', Icons.title),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),

            // Classification selector
            Text(
              'Classification',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _classifications.map((classification) {
                final isSelected = _selectedClassification == classification;
                final classColor =
                    AppTheme.getClassificationColor(classification);
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppTheme.getClassificationIcon(classification),
                        size: 18,
                        color: isSelected ? Colors.white : classColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        classification[0].toUpperCase() +
                            classification.substring(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : classColor,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedClassification = classification;
                      if (!_isTaskType && _endTime == null) {
                        _endTime = _startTime!.add(const Duration(hours: 1));
                      }
                    });
                  },
                  backgroundColor: classColor.withOpacity(0.1),
                  selectedColor: classColor,
                  side: BorderSide(
                    color: isSelected
                        ? classColor
                        : classColor.withOpacity(0.3),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String?>(
              value: _selectedCategory,
              style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: _buildInputDecoration(
                  'Category (Optional)', Icons.folder_outlined),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No category'),
                ),
                ...dataProvider.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: () => _selectDateTime(true),
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: _buildInputDecoration(
                  _isTaskType ? 'Due Date/Time' : 'Start Date/Time',
                  Icons.event,
                ),
                child: Text(
                  _isAllDay
                      ? DateFormat('EEE, MMM d, y').format(_startTime!)
                      : DateFormat('EEE, MMM d, y • h:mm a')
                          .format(_startTime!),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (!_isTaskType) ...[
              InkWell(
                onTap: () => _selectDateTime(false),
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: _buildInputDecoration(
                      'End Date/Time', Icons.event_available),
                  child: Text(
                    _isAllDay
                        ? DateFormat('EEE, MMM d, y').format(_endTime!)
                        : DateFormat('EEE, MMM d, y • h:mm a')
                            .format(_endTime!),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.getClassificationColor(_selectedClassification)
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.getClassificationColor(_selectedClassification)
                        .withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'All-day event',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Event lasts the entire day'),
                  value: _isAllDay,
                  onChanged: (value) => setState(() => _isAllDay = value),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_isTaskType) ...[
              DropdownButtonFormField<String>(
                value: _estimatedDuration,
                style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: _buildInputDecoration(
                    'Estimated Duration', Icons.timer_outlined),
                items: _durations.map((duration) {
                  return DropdownMenuItem(
                    value: duration,
                    child: Text(duration),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _estimatedDuration = value!),
              ),
              const SizedBox(height: 20),
            ],

            TextFormField(
              controller: _locationController,
              style: const TextStyle(fontSize: 17),
              decoration: _buildInputDecoration(
                  'Location (Optional)', Icons.location_on_outlined),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _notesController,
              maxLines: 4,
              style: const TextStyle(fontSize: 16),
              decoration: _buildInputDecoration(
                      'Notes (Optional)', Icons.notes)
                  .copyWith(
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedTab() {
    final color = AppTheme.getClassificationColor(_selectedClassification);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Priority Level',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _priorities.map((priority) {
              final isSelected = _selectedPriority == priority;
              final priorityColor = AppTheme.getPriorityColor(priority);
              return ChoiceChip(
                label: Text(
                  priority[0].toUpperCase() + priority.substring(1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : priorityColor,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedPriority = priority);
                },
                backgroundColor: priorityColor.withOpacity(0.1),
                selectedColor: priorityColor,
                side: BorderSide(
                  color: isSelected
                      ? priorityColor
                      : priorityColor.withOpacity(0.3),
                  width: 2,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Mark as Important',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Highlight this event with a star'),
                  value: _isImportant,
                  onChanged: (value) => setState(() => _isImportant = value),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  secondary: Icon(
                    Icons.star,
                    color: _isImportant ? AppTheme.warningAmber : null,
                    size: 28,
                  ),
                ),
                if (_isTaskType)
                  Column(
                    children: [
                      Divider(
                        color: color.withOpacity(0.2),
                        height: 1,
                      ),
                      SwitchListTile(
                        title: const Text(
                          'Mark as Completed',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('Check off this task'),
                        value: _isCompleted,
                        onChanged: (value) =>
                            setState(() => _isCompleted = value),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        secondary: Icon(
                          Icons.check_circle,
                          color:
                              _isCompleted ? AppTheme.successGreen : null,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reminders (${_reminders.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              FilledButton.icon(
                onPressed: _addReminder,
                icon: const Icon(Icons.add_alert, size: 20),
                label: const Text('Add Reminder'),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          if (_reminders.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...List.generate(_reminders.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: color,
                    ),
                  ),
                  title: Text(
                    DateFormat('MMM d, h:mm a').format(_reminders[index]),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () => _removeReminder(index),
                    icon: const Icon(Icons.close),
                    color: AppTheme.errorRed,
                  ),
                  dense: true,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentsTab() {
    final color = AppTheme.getClassificationColor(_selectedClassification);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voice Notes (${_voiceNotes.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              FilledButton.icon(
                onPressed: _recordVoiceNote,
                icon: const Icon(Icons.mic, size: 20),
                label: const Text('Record'),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          if (_voiceNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...List.generate(_voiceNotes.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: VoiceNotePlayer(
                  voiceNote: _voiceNotes[index],
                  onDelete: () => _removeVoiceNote(index),
                ),
              );
            }),
          ] else
            Container(
              margin: const EdgeInsets.only(top: 32),
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.mic_none,
                      size: 64,
                      color: color.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No voice notes yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Record" to add a voice note',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}