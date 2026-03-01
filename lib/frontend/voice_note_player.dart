/// VoiceNotePlayer - Audio Playback Widget
/// 
/// Reusable widget for playing voice notes attached to events.
/// 
/// Features:
/// - Play/pause controls with progress slider
/// - Duration display (current/total time)
/// - Visual waveform simulation
/// - Delete button for removing voice note
/// - Tap to play/pause
/// - Audio streaming from stored file path
/// 
/// Can be used anywhere voice notes need to be played back
/// (events, event details, voice note list, etc.)

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import '../backend/models.dart';
import 'theme.dart';

class VoiceNotePlayer extends StatefulWidget {
  final VoiceNote voiceNote;
  final VoidCallback? onDelete;

  const VoiceNotePlayer({
    super.key,
    required this.voiceNote,
    this.onDelete,
  });

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _duration = widget.voiceNote.duration;
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _currentPosition = Duration.zero;
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        final file = File(widget.voiceNote.filePath);
        if (await file.exists()) {
          // Stop any existing playback first
          await _audioPlayer.stop();
          // Play the file
          await _audioPlayer.play(DeviceFileSource(widget.voiceNote.filePath));
          print('Playing audio from: ${widget.voiceNote.filePath}');
        } else {
          if (mounted) {
              AppTheme.showTopNotification(
                context,
                'Audio file could not be found.',
                type: NotificationType.error,
              );
            }
        }
      } catch (e) {
        print('Error playing audio: $e');
        if (mounted) {
            AppTheme.showTopNotification(
              context,
              'Could not play audio. The file may be corrupted.',
              type: NotificationType.error,
            );
          }
      }
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
    final primaryColor = Theme.of(context).colorScheme.secondary;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    foregroundColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: _currentPosition.inSeconds.toDouble(),
                          max: _duration.inSeconds.toDouble(),
                          activeColor: primaryColor,
                          inactiveColor: primaryColor.withValues(alpha: 0.3),
                          onChanged: (value) async {
                            final position = Duration(seconds: value.toInt());
                            await _audioPlayer.seek(position);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    color: AppTheme.errorRed,
                  ),
              ],
            ),
            if (widget.voiceNote.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.voiceNote.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
