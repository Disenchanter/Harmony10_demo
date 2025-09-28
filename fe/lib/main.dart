import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'models.dart';
import 'api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harmony10 Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MusicHarmonyPage(),
    );
  }
}

enum AppMode { harmonize, evaluate }

class MusicHarmonyPage extends StatefulWidget {
  const MusicHarmonyPage({super.key});

  @override
  State<MusicHarmonyPage> createState() => _MusicHarmonyPageState();
}

class _MusicHarmonyPageState extends State<MusicHarmonyPage> {
  // State
  AppMode currentMode = AppMode.harmonize;
  bool isRecording = false;
  bool countdownStarted = false; // Tracks whether the countdown has started
  int recordingTime = 10;
  Timer? recordingTimer;
  
  // Note mapping (C4–B4)
  static const Map<String, int> noteMap = {
    'C': 60, // C4
    'D': 62, // D4
    'E': 64, // E4
    'F': 65, // F4
    'G': 67, // G4
    'A': 69, // A4
    'B': 71, // B4
  };
  
  // Recorded events
  List<MusicEvent> recordedEvents = [];
  
  // Result data
  EvaluateResponse? evaluationResult;
  String? midiFilePath;
  bool isLoading = false;
  String? errorMessage;
  
  // Audio playback
  AudioPlayer? audioPlayer;
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  @override
  void dispose() {
    recordingTimer?.cancel();
    audioPlayer?.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      isRecording = true;
      countdownStarted = false; // Reset countdown state
      recordingTime = 10;
      recordedEvents.clear();
      evaluationResult = null;
      midiFilePath = null;
      errorMessage = null;
    });
  }

  void _startCountdown() {
    if (countdownStarted) return; // Avoid starting multiple timers
    
    setState(() {
      countdownStarted = true;
    });

    recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        recordingTime--;
      });

      if (recordingTime <= 0) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    recordingTimer?.cancel();
    setState(() {
      isRecording = false;
      countdownStarted = false; // Reset countdown state
    });
    
    if (recordedEvents.isNotEmpty) {
      _processRecording();
    } else {
      setState(() {
        errorMessage = 'No notes were recorded';
      });
    }
  }

  void _onNotePressed(String noteName) {
    if (!isRecording) return;

    // Start the countdown on the first note
    if (!countdownStarted) {
      _startCountdown();
    }

    final currentSecond = 10 - recordingTime;
    final noteValue = noteMap[noteName]!;

    setState(() {
      // Remove events at the same second (keep the latest)
      recordedEvents.removeWhere((event) => event.tSec == currentSecond);
      
      // Add the new event
      recordedEvents.add(MusicEvent(
        tSec: currentSecond,
        note: noteValue,
      ));
    });
  }

  Future<void> _processRecording() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (currentMode == AppMode.harmonize) {
        await _handleHarmonize();
      } else {
        await _handleEvaluate();
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleHarmonize() async {
    final midiData = await ApiService.harmonize(recordedEvents);
    
    // Save the MIDI file alongside the executable
    final executablePath = Platform.resolvedExecutable;
    final executableDir = Directory(executablePath).parent.path;
    
    // Ensure the midi subdirectory exists
    final midiDir = Directory('$executableDir/midi');
    if (!await midiDir.exists()) {
      await midiDir.create(recursive: true);
    }
    
    final file = File('${midiDir.path}/harmony_${DateTime.now().millisecondsSinceEpoch}.mid');
    await file.writeAsBytes(midiData);
    
    // Debug output
    print('Executable path: $executablePath');
    print('Application directory: $executableDir');
    print('MIDI file saved at: ${file.path}');
    print('MIDI data size: ${midiData.length} bytes');
    print('File exists: ${await file.exists()}');
    
    setState(() {
      midiFilePath = file.path;
    });
  }

  Future<void> _handleEvaluate() async {
    final result = await ApiService.evaluate(recordedEvents);
    
    setState(() {
      evaluationResult = result;
    });
  }



  Future<void> _initializeAudioPlayer() async {
    if (audioPlayer == null) {
      audioPlayer = AudioPlayer();
      
      // Listen for playback state changes
      audioPlayer!.onPlayerStateChanged.listen((state) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      });
      
      // Track the playback position
      audioPlayer!.onPositionChanged.listen((position) {
        setState(() {
          currentPosition = position;
        });
      });
      
      // Track the total duration
      audioPlayer!.onDurationChanged.listen((duration) {
        setState(() {
          totalDuration = duration;
        });
      });
    }
  }

  Future<void> _playMidiFile() async {
    if (midiFilePath == null) return;
    
    try {
      await _initializeAudioPlayer();
      
      // Verify the file exists
      final file = File(midiFilePath!);
      if (!await file.exists()) {
        setState(() {
          errorMessage = 'MIDI file not found: $midiFilePath';
        });
        return;
      }
      
      print('Starting MIDI playback: $midiFilePath');
      print('File size: ${await file.length()} bytes');
      
      // Attempt to play using DeviceFileSource
      await audioPlayer!.play(DeviceFileSource(midiFilePath!));
      
      print('Playback command issued');
      
    } catch (e) {
      print('Error while playing MIDI file: $e');
      setState(() {
        errorMessage = 'Playback failed: $e\n\nPossible reasons include:\n1. The MIDI file format is not supported\n2. The system audio device has an issue\n3. The audio driver reported an error\n\nTry opening the file with an external player.';
      });
    }
  }

  Future<void> _pausePlayback() async {
    if (audioPlayer != null) {
      await audioPlayer!.pause();
    }
  }

  Future<void> _stopPlayback() async {
    if (audioPlayer != null) {
      await audioPlayer!.stop();
      setState(() {
        currentPosition = Duration.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Harmony Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top mode toggle
            _buildModeToggle(),
            
            const SizedBox(height: 20),
            
            // Recording status and countdown
            _buildRecordingStatus(),
            
            const SizedBox(height: 30),
            
            // Seven white key buttons
            _buildPianoKeys(),
            
            const SizedBox(height: 30),
            
            // Recording control buttons
            _buildRecordingControls(),
            
            const SizedBox(height: 20),
            
            // Result display area
            Container(
              height: 300, // Fixed height to replace Expanded
              child: SingleChildScrollView(
                child: _buildResultArea(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton('Harmonize', AppMode.harmonize),
          _buildModeButton('Evaluate', AppMode.evaluate),
        ],
      ),
    );
  }

  Widget _buildModeButton(String text, AppMode mode) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => currentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingStatus() {
    return Column(
      children: [
        Text(
          isRecording 
            ? (countdownStarted ? 'Recording...' : 'Waiting for the first note...') 
            : 'Ready to record',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        if (isRecording && countdownStarted)
          Text(
            '${recordingTime}s',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: recordingTime <= 3 ? Colors.red : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (isRecording && !countdownStarted)
          const Text(
            'Tap any white key to start the countdown',
            style: TextStyle(color: Colors.orange, fontSize: 16),
          ),
      ],
    );
  }

  Widget _buildPianoKeys() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: noteMap.keys.map((noteName) => _buildPianoKey(noteName)).toList(),
    );
  }

  Widget _buildPianoKey(String noteName) {
    final isPressed = recordedEvents.any((event) => 
        event.note == noteMap[noteName] && 
        event.tSec == (10 - recordingTime));
    
    return GestureDetector(
      onTap: () => _onNotePressed(noteName),
      child: Container(
        width: 40,
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isPressed ? Colors.blue[300] : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Center(
          child: Text(
            noteName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isPressed ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: isRecording ? null : _startRecording,
        icon: const Icon(Icons.fiber_manual_record),
        label: const Text('Start recording'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (currentMode == AppMode.harmonize && midiFilePath != null) {
      return _buildHarmonizeResult();
    }

    if (currentMode == AppMode.evaluate && evaluationResult != null) {
      return _buildEvaluateResult();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            currentMode == AppMode.harmonize ? Icons.music_note : Icons.assessment,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            currentMode == AppMode.harmonize
                ? 'Record a melody to generate harmony'
                : 'Record your performance for evaluation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the white keys above to record notes',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmonizeResult() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, size: 48, color: Colors.green),
        const SizedBox(height: 12),
        const Text(
          'MIDI file generated successfully!',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'File: ${midiFilePath!.split('/').last}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),
        const Text(
          'Includes melody and harmony tracks',
          style: TextStyle(color: Colors.blue, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          '${recordedEvents.length} notes recorded',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 16),
        // Audio playback controls
        _buildAudioPlayerControls(),
      ],
    );
  }

  Widget _buildAudioPlayerControls() {
    return Column(
      children: [
        // Playback progress bar (when total duration is available)
        if (totalDuration.inMilliseconds > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  _formatDuration(currentPosition),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Expanded(
                  child: Slider(
                    value: currentPosition.inMilliseconds.toDouble(),
                    max: totalDuration.inMilliseconds.toDouble(),
                    onChanged: (value) async {
                      final position = Duration(milliseconds: value.toInt());
                      await audioPlayer?.seek(position);
                    },
                  ),
                ),
                Text(
                  _formatDuration(totalDuration),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Playback control buttons
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     // Play/pause button
        //     ElevatedButton.icon(
        //       onPressed: isPlaying ? _pausePlayback : _playMidiFile,
        //       icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
        //       label: Text(isPlaying ? 'Pause' : 'Play'),
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: isPlaying ? Colors.orange : Colors.green,
        //         foregroundColor: Colors.white,
        //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //       ),
        //     ),
            
        //     const SizedBox(width: 12),
            
        //     // Stop button
        //     if (isPlaying || currentPosition.inMilliseconds > 0)
        //       ElevatedButton.icon(
        //         onPressed: _stopPlayback,
        //         icon: const Icon(Icons.stop),
        //         label: const Text('Stop'),
        //         style: ElevatedButton.styleFrom(
        //           backgroundColor: Colors.red,
        //           foregroundColor: Colors.white,
        //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //         ),
        //       ),
            

        //   ],
        // ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildEvaluateResult() {
    final result = evaluationResult!;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Overall score display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getScoreColor(result.score).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getScoreColor(result.score)),
            ),
            child: Column(
              children: [
                Text(
                  '${result.score.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(result.score),
                  ),
                ),
                Text(
                  'Total score',
                  style: TextStyle(
                    fontSize: 16,
                    color: _getScoreColor(result.score),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Subscores
          Row(
            children: [
              Expanded(
                child: _buildSubScore('Accuracy', result.subscores['accuracy'] ?? 0),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSubScore('Timing', result.subscores['timing'] ?? 0),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Suggestions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggestions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.advice,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          // Mistake details
          if (result.mistakes.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildMistakesList(result.mistakes),
          ],
        ],
      ),
    );
  }

  Widget _buildSubScore(String label, double score) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMistakesList(List<Mistake> mistakes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mistake details (${mistakes.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...mistakes.take(5).map((mistake) => _buildMistakeItem(mistake)),
        if (mistakes.length > 5)
          Text(
            '... ${mistakes.length - 5} more mistakes',
            style: const TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildMistakeItem(Mistake mistake) {
    String errorDescription;
    IconData errorIcon;
    Color errorColor;

    switch (mistake.errorType) {
      case 'wrong_note':
        errorDescription = 'At ${mistake.timeSec}s: Wrong note played';
        errorIcon = Icons.music_off;
        errorColor = Colors.orange;
        break;
      case 'missing_note':
        errorDescription = 'At ${mistake.timeSec}s: Missing note';
        errorIcon = Icons.remove_circle;
        errorColor = Colors.red;
        break;
      case 'extra_note':
        errorDescription = 'At ${mistake.timeSec}s: Extra note';
        errorIcon = Icons.add_circle;
        errorColor = Colors.purple;
        break;
      default:
        errorDescription = 'At ${mistake.timeSec}s: Unknown issue';
        errorIcon = Icons.error;
        errorColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(errorIcon, size: 16, color: errorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorDescription,
              style: TextStyle(fontSize: 12, color: errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}