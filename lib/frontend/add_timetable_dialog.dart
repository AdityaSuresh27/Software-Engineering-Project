// add_timetable_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../backend/data_provider.dart';
import '../backend/timetable_models.dart';
import 'theme.dart';
import 'package:intl/intl.dart';

class AddTimetableDialog extends StatefulWidget {
  final TimetableEntry? editEntry;

  const AddTimetableDialog({super.key, this.editEntry});

  @override
  State<AddTimetableDialog> createState() => _AddTimetableDialogState();
}

class _AddTimetableDialogState extends State<AddTimetableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _instructorController = TextEditingController();
  final _roomController = TextEditingController();

  List<int> _selectedDays = [];
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  int _periodDurationMinutes = 60; // Default 1 hour
  String? _selectedCategory;
  Color _selectedColor = AppTheme.classBlue;

  DateTime? _semesterStart;
  DateTime? _semesterEnd;

  final List<int> _durationOptions = [30, 45, 50, 60, 75, 90, 120, 180]; // in minutes

  @override
  void initState() {
    super.initState();

    if (widget.editEntry != null) {
      _courseNameController.text = widget.editEntry!.courseName;
      _courseCodeController.text = widget.editEntry!.courseCode ?? '';
      _instructorController.text = widget.editEntry!.instructor ?? '';
      _roomController.text = widget.editEntry!.room ?? '';
      _selectedDays = List.from(widget.editEntry!.daysOfWeek);
      _startTime = widget.editEntry!.startTime;
      _selectedCategory = widget.editEntry!.category;
      _semesterStart = widget.editEntry!.semesterStart;
      _semesterEnd = widget.editEntry!.semesterEnd;
      
      if (widget.editEntry!.color != null) {
        _selectedColor = Color(int.parse(widget.editEntry!.color!.replaceFirst('#', '0xFF')));
      }
      
      // Calculate period duration from existing entry
      final startMinutes = widget.editEntry!.startTime.hour * 60 + widget.editEntry!.startTime.minute;
      final endMinutes = widget.editEntry!.endTime.hour * 60 + widget.editEntry!.endTime.minute;
      _periodDurationMinutes = endMinutes - startMinutes;
    } else {
      // Set defaults for new entries
      _semesterStart = DateTime.now();
      _semesterEnd = DateTime.now().add(const Duration(days: 180)); // 6 months
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _instructorController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  TimeOfDay _calculateEndTime() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = startMinutes + _periodDurationMinutes;
    return TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  void _saveTimetableEntry() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select at least one day'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final endTime = _calculateEndTime();

      if (widget.editEntry != null) {
        // Show edit options dialog
        _showEditOptionsDialog(context, dataProvider, endTime);
      } else {
        // Create new entry
        final entry = TimetableEntry(
          id: const Uuid().v4(),
          courseName: _courseNameController.text,
          courseCode: _courseCodeController.text.isEmpty ? null : _courseCodeController.text,
          instructor: _instructorController.text.isEmpty ? null : _instructorController.text,
          room: _roomController.text.isEmpty ? null : _roomController.text,
          daysOfWeek: _selectedDays,
          startTime: _startTime,
          endTime: endTime,
          category: _selectedCategory,
          color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
          semesterStart: _semesterStart,
          semesterEnd: _semesterEnd,
        );
        dataProvider.addTimetableEntry(entry);
        
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Class added to timetable'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditOptionsDialog(BuildContext context, DataProvider dataProvider, TimeOfDay endTime) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Options'),
        content: const Text('Do you want to apply changes to all instances of this class or just this specific occurrence?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              // Edit single instance - convert to manual event
              Navigator.pop(context); // Close options dialog
              Navigator.pop(context); // Close edit dialog
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('This feature edits the entire series. Use the calendar to edit single classes.'),
                  backgroundColor: AppTheme.warningAmber,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('This Class Only'),
          ),
          FilledButton(
            onPressed: () {
              // Update all instances
              final updated = TimetableEntry(
                id: widget.editEntry!.id,
                courseName: _courseNameController.text,
                courseCode: _courseCodeController.text.isEmpty ? null : _courseCodeController.text,
                instructor: _instructorController.text.isEmpty ? null : _instructorController.text,
                room: _roomController.text.isEmpty ? null : _roomController.text,
                daysOfWeek: _selectedDays,
                startTime: _startTime,
                endTime: endTime,
                category: _selectedCategory,
                color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
                semesterStart: _semesterStart,
                semesterEnd: _semesterEnd,
                excludedDates: widget.editEntry!.excludedDates,
              );
              dataProvider.updateTimetableEntry(updated);
              
              Navigator.pop(context); // Close options dialog
              Navigator.pop(context); // Close edit dialog

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All classes in series updated'),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: _selectedColor,
            ),
            child: const Text('All Classes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final endTime = _calculateEndTime();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_selectedColor, _selectedColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_view_week, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.editEntry != null ? 'Edit Timetable Entry' : 'Add to Timetable',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _courseNameController,
                        decoration: _buildInputDecoration('Class Name', Icons.school_outlined),
                        validator: (value) => value?.isEmpty ?? true ? 'Class name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _courseCodeController,
                        decoration: _buildInputDecoration('Course Code (Optional)', Icons.tag),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _instructorController,
                        decoration: _buildInputDecoration('Instructor (Optional)', Icons.person_outline),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _roomController,
                        decoration: _buildInputDecoration('Room/Location (Optional)', Icons.room_outlined),
                      ),
                      const SizedBox(height: 20),

                      // Days of week
                      Text(
                        'Days of Week',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(7, (index) {
                          final day = index + 1;
                          final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final isSelected = _selectedDays.contains(day);

                          return FilterChip(
                            label: Text(dayNames[index]),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDays.add(day);
                                  _selectedDays.sort();
                                } else {
                                  _selectedDays.remove(day);
                                }
                              });
                            },
                            backgroundColor: _selectedColor.withOpacity(0.1),
                            selectedColor: _selectedColor.withOpacity(0.3),
                            checkmarkColor: _selectedColor,
                            side: BorderSide(
                              color: isSelected ? _selectedColor : _selectedColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),

                      // Start time
                      Text(
                        'Class Timing',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectStartTime,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: _buildInputDecoration('Start Time', Icons.access_time),
                          child: Text(
                            _startTime.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Period duration
                      DropdownButtonFormField<int>(
                        value: _periodDurationMinutes,
                        decoration: _buildInputDecoration('Period Duration', Icons.timer_outlined),
                        items: _durationOptions.map((minutes) {
                          return DropdownMenuItem(
                            value: minutes,
                            child: Text(_formatDuration(minutes)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _periodDurationMinutes = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Calculated end time (display only)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: _selectedColor),
                            const SizedBox(width: 12),
                            Text(
                              'End Time: ${endTime.format(context)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _selectedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Category
                      DropdownButtonFormField<String?>(
                        value: _selectedCategory,
                        decoration: _buildInputDecoration('Category (Optional)', Icons.folder_outlined),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('No category')),
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

                      // Date Range
                      Text(
                        'Class Duration',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _semesterStart ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() => _semesterStart = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: _buildInputDecoration('Start Date', Icons.calendar_today),
                                child: Text(
                                  _semesterStart != null
                                      ? DateFormat('MMM d, y').format(_semesterStart!)
                                      : 'Select date',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _semesterEnd ?? DateTime.now().add(const Duration(days: 180)),
                                  firstDate: _semesterStart ?? DateTime.now(),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() => _semesterEnd = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: _buildInputDecoration('End Date', Icons.event),
                                child: Text(
                                  _semesterEnd != null
                                      ? DateFormat('MMM d, y').format(_semesterEnd!)
                                      : 'Select date',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: _selectedColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Class events will be auto-generated for this period',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // Color picker
                      Text(
                        'Color',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          AppTheme.classBlue,
                          AppTheme.assignmentPurple,
                          AppTheme.examOrange,
                          AppTheme.meetingTeal,
                          AppTheme.personalGreen,
                          AppTheme.deadlineRed,
                          AppTheme.otherGray,
                        ].map((color) {
                          final isSelected = _selectedColor == color;
                          return InkWell(
                            onTap: () => setState(() => _selectedColor = color),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.05),
                border: Border(
                  top: BorderSide(color: _selectedColor.withOpacity(0.2)),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saveTimetableEntry,
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(
                    widget.editEntry != null ? 'Update Entry' : 'Add to Timetable',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _selectedColor),
      filled: true,
      fillColor: _selectedColor.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _selectedColor.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _selectedColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _selectedColor, width: 2),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      }
      return '$hours hr $mins min';
    }
  }
}