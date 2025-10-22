import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/bluetooth_service.dart';
import 'fret_board_widget.dart';
import 'music_selection_widget.dart';

/// Scale Practice Page Widget
class ScalePracticePage extends StatefulWidget {
  final ESP32BluetoothService bluetoothService;

  const ScalePracticePage({required this.bluetoothService, Key? key})
    : super(key: key);

  @override
  _ScalePracticePageState createState() => _ScalePracticePageState();
}

class _ScalePracticePageState extends State<ScalePracticePage> {
  // State variables for scale selection
  String? selectedNote;
  int noteIndex = 0;
  String scaleType = "Major";
  String showOption = "Finger position";
  List<String> scaleNotes = [];
  List<List<int>> scalePositions = [];

  // Add variable to store scale data
  Map<String, dynamic>? scaleData;

  // Metronome and animation state
  int selectedBPM = 60;
  bool isPlaying = false;
  int currentPositionIndex = -1; // -1 means not started, -2 means in count-in
  Timer? metronomeTimer;
  int countInBeats = 0; // Counter for 2-bar count-in (8 beats at 4/4)
  int totalBeatCount = 0; // Total beat count for maintaining accent pattern
  late AudioPlayer _audioPlayer;
  String scaleDirection = "Ascending"; // Ascending, Descending, or Both
  bool isAscending = true; // Track current direction when playing "Both"

  // List of musical notes for selection
  List<String> notes = [
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B",
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setVolume(1.0);
    // Set release mode to release - allows rapid successive sounds
    _audioPlayer.setReleaseMode(ReleaseMode.release);
    _loadScaleData();
  }

  @override
  void dispose() {
    metronomeTimer?.cancel();
    _audioPlayer.dispose();
    // Clear the LED display when leaving the scale practice screen
    widget.bluetoothService.clearDisplay();
    super.dispose();
  }

  // Load scale data from JSON file
  Future<void> _loadScaleData() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/data/scales.json',
      );
      setState(() {
        scaleData = json.decode(jsonString);
        print("Scale data loaded successfully");
        // print(scaleData);
      });
    } catch (e) {
      print('Error loading scale data: $e');
    }
  }

  // Convert display note name to JSON key format
  String _noteToJsonKey(String note) {
    Map<String, String> noteMap = {
      "C": "c",
      "C#": "c_sharp",
      "D": "d",
      "D#": "d_sharp",
      "E": "e",
      "F": "f",
      "F#": "f_sharp",
      "G": "g",
      "G#": "g_sharp",
      "A": "a",
      "A#": "a_sharp",
      "B": "b",
    };
    return noteMap[note] ?? "c";
  }

  // Process scale information when selection changes
  void _processScaleData() async {
    // Stop metronome when scale changes
    if (isPlaying) {
      _stopMetronome();
    }

    // Don't send anything if no note is selected
    if (selectedNote == null) {
      print("No scale selected yet");
      return;
    }

    if (scaleData == null) {
      print('Scale data not loaded yet');
      return;
    }

    try {
      // Get scale type key (major/minor in lowercase)
      String scaleTypeKey = scaleType.toLowerCase();

      // Get note key (e.g., "c", "c_sharp", etc.)
      String noteKey = _noteToJsonKey(selectedNote!);

      // Access scale data: scaleData["major"]["c"] or scaleData["minor"]["c_sharp"]
      Map<String, dynamic>? scaleInfo = scaleData![scaleTypeKey]?[noteKey];

      if (scaleInfo != null) {
        // Extract scale information from JSON
        List<String> notes = List<String>.from(scaleInfo['notes'] ?? []);
        List<dynamic> positionsRaw = scaleInfo['positions'] ?? [];
        List<List<int>> positions = positionsRaw
            .map((pos) => List<int>.from(pos))
            .toList();

        // Update UI state with scale information
        setState(() {
          scaleNotes = notes;
          scalePositions = positions;
        });

        // Create complete scale message for logging
        Map<String, dynamic> scaleMessage = {
          "scale": "$selectedNote $scaleType Scale",
          "notes": notes,
          "positions": positions,
        };

        // Log the complete scale information
        String scaleJsonString = json.encode(scaleMessage);
        print("Complete scale data: $scaleJsonString");
        print(
          "Scale selected: $selectedNote $scaleType with ${positions.length} positions",
        );

        // Clear any previous scale display on hardware
        if (widget.bluetoothService.connected) {
          widget.bluetoothService.sendScaleData("clear");
          print("Cleared hardware display for new scale selection");
        }

        // Note: We don't send the full scale anymore - individual notes are sent during playback
      } else {
        print("Scale not found: $scaleTypeKey -> $noteKey");
        // Fallback message - send error indicator to scale characteristic
        String fallbackInfo = "[]"; // Empty array pattern for error
        print("Sending fallback scale pattern to ESP32: $fallbackInfo");
        widget.bluetoothService.sendScaleData(fallbackInfo);
      }
    } catch (e) {
      print('Error processing scale data: $e');
      // Fallback to error pattern on any exception
      String errorPattern = "[]";
      print("Sending error pattern to ESP32: $errorPattern");
      widget.bluetoothService.sendScaleData(errorPattern);
    }
  }

  // Play metronome click sound
  void _playMetronomeClick({bool isAccent = false}) {
    try {
      // Play sound directly without stopping - let it naturally complete
      // The click sounds are very short (50-80ms) so won't overlap
      if (isAccent) {
        // Accent beat (first beat of bar) - higher pitch, longer duration
        print('Playing ACCENT click');
        _audioPlayer.play(AssetSource('audio/click_accent.wav'));
        // Also add haptic feedback for better feel
        HapticFeedback.heavyImpact();
      } else {
        // Regular beat - normal click
        print('Playing regular click');
        _audioPlayer.play(AssetSource('audio/click.wav'));
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      print('Error playing metronome sound: $e');
      // Fallback to haptic only if audio fails
      if (isAccent) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  // Get positions list based on selected direction
  List<List<int>> _getDirectedPositions() {
    if (scaleDirection == "Ascending") {
      return scalePositions;
    } else if (scaleDirection == "Descending") {
      return scalePositions.reversed.toList();
    } else {
      // Both - ascending then descending
      // Play 8th note twice (once at end of ascending, once at start of descending)
      List<List<int>> both = [...scalePositions];
      // Add full descending scale (all notes including the last note again)
      for (int i = scalePositions.length - 1; i >= 0; i--) {
        both.add(scalePositions[i]);
      }
      return both;
    }
  }

  // Start metronome with 2-bar count-in
  void _startMetronome() {
    if (scalePositions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a scale first')));
      return;
    }

    // Clear LEDs before starting metronome
    _sendCurrentNoteToHardware(clear: true);

    setState(() {
      isPlaying = true;
      currentPositionIndex = -2; // -2 indicates count-in phase
      countInBeats = 0;
      totalBeatCount = 0; // Reset total beat count
    });

    final int beatInterval = (60000 / selectedBPM)
        .round(); // milliseconds per beat

    // Play the first beat immediately
    _playBeatAndUpdate();

    // Then set up periodic timer for subsequent beats
    metronomeTimer = Timer.periodic(Duration(milliseconds: beatInterval), (
      timer,
    ) {
      _playBeatAndUpdate();
    });
  }

  // Helper method to play beat and update state
  void _playBeatAndUpdate() {
    // Check if widget is still mounted before updating state
    if (!mounted) return;

    // Get the directed positions list each time
    final directedPositions = _getDirectedPositions();

    if (currentPositionIndex == -2) {
      // Count-in phase (2 bars = 8 beats in 4/4 time)
      // Beat pattern: 1(accent), 2, 3, 4, 5(accent), 6, 7, 8
      // Accents are at beats 1, 5, 9, 13... (every 4 beats starting from 1)
      bool isAccent = (totalBeatCount % 4 == 0);

      _playMetronomeClick(isAccent: isAccent);

      // Update state variables without rebuilding yet
      countInBeats++;
      totalBeatCount++;

      if (countInBeats >= 8) {
        // Count-in complete, next beat (beat 9) will start scale playback
        // Set to -1 so that next beat will be position 0
        currentPositionIndex = -1;

        // Clear hardware display before starting
        _sendCurrentNoteToHardware(clear: true);
      }

      // Single setState at the end to trigger rebuild
      if (mounted) {
        setState(() {});
      }
    } else {
      // Scale playback phase - play click first, then increment position
      // Continue accent pattern: beats 0, 4, 8, 12... (every 4 beats)
      bool isAccent = (totalBeatCount % 4 == 0);
      _playMetronomeClick(isAccent: isAccent);

      // Update state variables without rebuilding yet
      totalBeatCount++;
      currentPositionIndex++;

      // Special handling for "Both" mode: clear LEDs at transition point (after 8th note of ascending)
      if (scaleDirection == "Both" &&
          currentPositionIndex == scalePositions.length) {
        // We just played the 8th note (end of ascending), now clear before descending starts
        _sendCurrentNoteToHardware(clear: true);
        print("Both mode: Cleared LEDs after ascending, before descending");
      }

      // Loop back to start when reaching the end
      if (currentPositionIndex >= directedPositions.length) {
        // Clear LEDs before starting the next cycle
        _sendCurrentNoteToHardware(clear: true);
        currentPositionIndex = 0;
      }

      // Send current note position to hardware
      _sendCurrentNoteToHardware();

      // Single setState at the end to trigger rebuild
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Send current highlighted note position to ESP32 hardware
  void _sendCurrentNoteToHardware({bool clear = false}) {
    if (!widget.bluetoothService.connected) {
      // Don't send if not connected, but don't show error - just skip silently
      return;
    }

    if (clear) {
      // Send clear command to turn off all scale LEDs
      widget.bluetoothService.sendScaleData("clear");
      print("Sent clear command to hardware");
      return;
    }

    final directedPositions = _getDirectedPositions();

    if (currentPositionIndex >= 0 &&
        currentPositionIndex < directedPositions.length) {
      // Get current note position [string, fret]
      List<int> currentNote = directedPositions[currentPositionIndex];

      // Format as single note position: [string, fret]
      String noteData = currentNote.toString();

      // Send to hardware via scale characteristic
      widget.bluetoothService.sendScaleData(noteData);

      print(
        "Sent note to hardware: String ${currentNote[0]}, Fret ${currentNote[1]} -> $noteData",
      );
    }
  }

  // Stop metronome
  void _stopMetronome() {
    metronomeTimer?.cancel();

    // Clear hardware display when stopping
    _sendCurrentNoteToHardware(clear: true);

    setState(() {
      isPlaying = false;
      currentPositionIndex = -1;
      countInBeats = 0;
      totalBeatCount = 0;
      isAscending = true; // Reset direction
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scale selection interface using reusable widget
            MusicSelectionWidget(
              title: "Select a Scale",
              selectedNote: selectedNote,
              selectedType: scaleType,
              showOption: showOption,
              notes: notes,
              types: ["Major", "Minor"],
              onNoteChanged: (note, index) {
                setState(() {
                  selectedNote = note;
                  noteIndex = index;
                });
                _processScaleData();
              },
              onTypeChanged: (type) {
                setState(() {
                  scaleType = type;
                });
                _processScaleData();
              },
              onShowOptionChanged: (option) {
                setState(() {
                  showOption = option;
                });
              },
            ),

            SizedBox(height: 20),

            // Direction Selection
            Row(
              children: [
                Text(
                  "Direction: ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: scaleDirection,
                  items: ["Ascending", "Descending", "Both"]
                      .map(
                        (dir) => DropdownMenuItem(value: dir, child: Text(dir)),
                      )
                      .toList(),
                  onChanged: isPlaying
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              scaleDirection = val;
                            });
                          }
                        },
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    scaleDirection == "Ascending"
                        ? "↑ Low to High"
                        : scaleDirection == "Descending"
                        ? "↓ High to Low"
                        : "↑↓ Up then Down",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Metronome Controls (moved above fretboard)
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metronome Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),

                    // BPM Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tempo (BPM):',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        DropdownButton<int>(
                          value: selectedBPM,
                          items: [40, 60, 80, 100, 120, 140, 160, 180, 200]
                              .map(
                                (bpm) => DropdownMenuItem(
                                  value: bpm,
                                  child: Text('$bpm BPM'),
                                ),
                              )
                              .toList(),
                          onChanged: isPlaying
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedBPM = value!;
                                  });
                                },
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Count-in indicator
                    if (currentPositionIndex == -2)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Count-in: ${countInBeats}/8',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),

                    // Start/Stop Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: scalePositions.isEmpty
                            ? null
                            : () {
                                if (isPlaying) {
                                  _stopMetronome();
                                } else {
                                  _startMetronome();
                                }
                              },
                        icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          isPlaying ? 'Stop Metronome' : 'Start Metronome',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: isPlaying
                              ? Colors.red
                              : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Use the FretboardWidget for scales
            FretboardWidget(
              fretPositions: [], // Not used for scales
              title: "Scale Fretboard",
              isScaleMode: true,
              scalePositions: scalePositions, // Always show all positions
              selectedNote: selectedNote,
              selectedType: scaleType,
              notes: scaleNotes,
              currentHighlightIndex: currentPositionIndex,
              scaleDirection: scaleDirection, // Pass direction for highlighting
            ),
          ],
        ),
      ),
    );
  }
}
