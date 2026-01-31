import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'theme.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';

class VoiceRecorderDialog extends StatefulWidget {
  final String? eventId;
  final String? taskId;
  final String? contextType; // 'event', 'task', or null for standalone

  const VoiceRecorderDialog({
    super.key,
    this.eventId,
    this.taskId,
    this.contextType,
  });

  @override
  State<VoiceRecorderDialog> createState() => _VoiceRecorderDialogState();
}

class _VoiceRecorderDialogState extends State<VoiceRecorderDialog> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _duration = Duration.zero;
  Timer? _timer;
  String? _recordingPath;
  final _tagsController = TextEditingController();
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _recorder.start(const RecordConfig(), path: filePath);
        
        setState(() {
          _isRecording = true;
          _recordingPath = filePath;
          _duration = Duration.zero;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _duration = Duration(seconds: timer.tick);
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    setState(() => _isPaused = true);
    _timer?.cancel();
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    setState(() => _isPaused = false);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration = Duration(seconds: _duration.inSeconds + 1);
        });
      }
    });
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    
    if (path != null && mounted) {
      final voiceNote = VoiceNote(
        id: const Uuid().v4(),
        filePath: path,
        recordedAt: DateTime.now(),
        duration: _duration,
        tags: _tags,
      );

      // Save to event or task if provided
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      
      if (widget.eventId != null) {
        dataProvider.addVoiceNoteToEvent(widget.eventId!, voiceNote);
      } else if (widget.taskId != null) {
        dataProvider.addVoiceNoteToTask(widget.taskId!, voiceNote);
      }

      Navigator.pop(context, voiceNote);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.eventId != null || widget.taskId != null
                ? 'Voice note added!'
                : 'Voice note saved!',
          ),
          backgroundColor: AppTheme.accentClarity,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                size: 64,
                color: _isRecording ? Colors.red : AppTheme.accentFocus,
              ),
              const SizedBox(height: 16),
              
              Text(
                _isRecording 
                    ? (_isPaused ? 'Paused' : 'Recording...') 
                    : 'Ready to Record',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              if (widget.contextType != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentFocus.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Attaching to ${widget.contextType}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.accentFocus,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              Text(
                _formatDuration(_duration),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: _isRecording ? Colors.red : AppTheme.accentFocus,
                ),
              ),
              
              if (_isRecording) ...[
                const SizedBox(height: 24),
                TextField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: 'Add Tags (optional)',
                    hintText: 'e.g., important, chapter-3',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: _addTag,
                    ),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        backgroundColor: AppTheme.accentFocus.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: AppTheme.accentFocus,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
              
              const SizedBox(height: 24),
              
              if (!_isRecording) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.fiber_manual_record_rounded),
                    label: const Text('Start Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                        icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                        label: Text(_isPaused ? 'Resume' : 'Pause'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _stopRecording,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentClarity,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}