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

  const AddEventDialog({super.key, this.selectedDate, this.editEvent});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _subjectController = TextEditingController();

  String _selectedType = 'lecture';
  DateTime? _startTime;
  DateTime? _endTime;
  List<VoiceNote> _voiceNotes = [];
  bool _isImportant = false;
  List<DateTime> _reminders = [];

  final List<String> _eventTypes = ['lecture', 'lab', 'exam', 'submission', 'note'];

  @override
  void initState() {
    super.initState();
    if (widget.editEvent != null) {
      _titleController.text = widget.editEvent!.title;
      _locationController.text = widget.editEvent!.location ?? '';
      _notesController.text = widget.editEvent!.notes ?? '';
      _subjectController.text = widget.editEvent!.subject ?? '';
      _selectedType = widget.editEvent!.type;
      _startTime = widget.editEvent!.startTime;
      _endTime = widget.editEvent!.endTime;
      _voiceNotes = List.from(widget.editEvent!.voiceNotes);
      _isImportant = widget.editEvent!.isImportant;
      _reminders = List.from(widget.editEvent!.reminders);
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
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime! : _endTime!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startTime! : _endTime!),
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
            if (_endTime!.isBefore(_startTime!)) {
              _endTime = _startTime!.add(const Duration(hours: 1));
            }
          } else {
            _endTime = newDateTime;
          }
        });
      }
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
        initialTime: TimeOfDay.fromDateTime(_startTime!.subtract(const Duration(hours: 1))),
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
            const SnackBar(
              content: Text('Reminder must be before event start time'),
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
    if (_formKey.currentState!.validate()) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);

      if (widget.editEvent != null) {
        // Update existing event
        widget.editEvent!.title = _titleController.text;
        widget.editEvent!.type = _selectedType;
        widget.editEvent!.startTime = _startTime!;
        widget.editEvent!.endTime = _endTime!;
        widget.editEvent!.location = _locationController.text.isEmpty ? null : _locationController.text;
        widget.editEvent!.notes = _notesController.text.isEmpty ? null : _notesController.text;
        widget.editEvent!.subject = _subjectController.text.isEmpty ? null : _subjectController.text;
        widget.editEvent!.voiceNotes = _voiceNotes;
        widget.editEvent!.isImportant = _isImportant;
        widget.editEvent!.reminders = _reminders;
        dataProvider.updateEvent(widget.editEvent!);
      } else {
        // Create new event
        final event = Event(
          id: const Uuid().v4(),
          title: _titleController.text,
          type: _selectedType,
          startTime: _startTime!,
          endTime: _endTime!,
          location: _locationController.text.isEmpty ? null : _locationController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          subject: _subjectController.text.isEmpty ? null : _subjectController.text,
          voiceNotes: _voiceNotes,
          isImportant: _isImportant,
          reminders: _reminders,
        );
        dataProvider.addEvent(event);
      }

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editEvent != null ? 'Event updated!' : 'Event added!'),
          backgroundColor: AppTheme.accentClarity,
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
                      widget.editEvent != null ? 'Edit Event' : 'Add Event',
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
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Event Title *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.title_rounded),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      
                      // Type dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Type *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.category_rounded),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        items: _eventTypes.map((type) {
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
                      
                      // Start time
                      InkWell(
                        onTap: () => _selectDate(true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Start Time *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.access_time_rounded),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy • h:mm a').format(_startTime!),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // End time
                      InkWell(
                        onTap: () => _selectDate(false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Time *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.access_time_filled_rounded),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy • h:mm a').format(_endTime!),
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
                      
                      // Subject field
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: 'Subject/Course',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.book_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // Location field
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // Notes field
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
                      
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _saveEvent,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(widget.editEvent != null ? 'Update Event' : 'Add Event'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentFocus,
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