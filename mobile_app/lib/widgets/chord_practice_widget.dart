import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/bluetooth_service.dart';
import 'fret_board_widget.dart';
import 'music_selection_widget.dart';

/// Chord Practice Page Widget
class ChordPracticePage extends StatefulWidget {
  final ESP32BluetoothService bluetoothService;

  const ChordPracticePage({required this.bluetoothService, Key? key})
    : super(key: key);

  @override
  _ChordPracticePageState createState() => _ChordPracticePageState();
}

class _ChordPracticePageState extends State<ChordPracticePage> {
  // State variables for chord selection
  String selectedNote = "C";
  int noteIndex = 0;
  String chordType = "Major";
  String showOption = "Finger position";
  List<String> chordNotes = ["C", "E", "G"];
  List<int> fretPositions = [];
  List<int> fingerPositions = [];
  List<String> noStrumStrings = [];

  // Add variable to store chord data
  Map<String, dynamic>? chordData;

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
    _loadChordData();
  }

  @override
  void dispose() {
    // Clear the LED display when leaving the chord practice screen
    widget.bluetoothService.clearDisplay();
    super.dispose();
  }

  // Load chord data from JSON file
  Future<void> _loadChordData() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/data/chords.json',
      );
      setState(() {
        chordData = json.decode(jsonString);
        print("Chord data loaded successfully");
        // print(chordData);
      });
    } catch (e) {
      print('Error loading chord data: $e');
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

  // Send chord information to ESP32 when selection changes
  void _sendChordToESP32() async {
    if (chordData == null) {
      print('Chord data not loaded yet');
      return;
    }

    try {
      // Get chord type key (major/minor in lowercase)
      String chordTypeKey = chordType.toLowerCase();

      // Get note key (e.g., "c", "c_sharp", etc.)
      String noteKey = _noteToJsonKey(selectedNote);

      // Access chord data: chordData["major"]["c"] or chordData["minor"]["c_sharp"]
      Map<String, dynamic>? chordInfo = chordData![chordTypeKey]?[noteKey];

      if (chordInfo != null) {
        // Extract chord information from JSON
        List<String> notes = List<String>.from(chordInfo['notes'] ?? []);
        List<int> fretNum = List<int>.from(chordInfo['fret_num'] ?? []);
        List<int> fingerNum = List<int>.from(chordInfo['finger_pos'] ?? []);
        List<String> noStrum = List<String>.from(chordInfo['no_strum'] ?? []);

        // Update UI state with chord information
        setState(() {
          chordNotes = notes;
          fretPositions = fretNum;
          fingerPositions = fingerNum;
          noStrumStrings = noStrum;
        });

        // Convert fret positions to string for ESP32 transmission
        String fretPosString = fretNum.toString();
        String fingerPosString = fingerNum.toString();

        // Log the complete chord information
        Map<String, dynamic> chordMessageFull = {
          "chord": "$selectedNote $chordType",
          "notes": notes,
          "fret_positions": fretNum,
          "finger_positions": fingerNum,
          "no_strum": noStrum,
        };
        String chordJsonString = json.encode(chordMessageFull);
        print("Complete chord data: $chordJsonString");
        print("Fret positions array: $fretNum");
        print("Finger positions array: $fingerNum");
        print("Fret string to send: $fretPosString");
        print("Finger string to send: $fingerPosString");
        print("Combined data: $fretPosString|$fingerPosString");

        // Send both fret and finger positions to chord pixel characteristic
        // This targets the _chordPixelCharUUID in _pixelServiceUUID service
        widget.bluetoothService.sendChordData(fretPosString, fingerPosString);
      } else {
        print("Chord not found: $chordTypeKey -> $noteKey");
        // Fallback message - send error indicator to chord characteristic
        String fallbackInfo = "[-1, -1, -1, -1, -1, -1]"; // Error pattern
        print("Sending fallback chord pattern to ESP32: $fallbackInfo");
        widget.bluetoothService.sendChordData(fallbackInfo);
      }
    } catch (e) {
      print('Error processing chord data: $e');
      // Fallback to error pattern on any exception
      String errorPattern = "[-1, -1, -1, -1, -1, -1]";
      print("Sending error pattern to ESP32: $errorPattern");
      widget.bluetoothService.sendChordData(errorPattern);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chord selection interface using reusable widget
            MusicSelectionWidget(
              title: "Select a Chord",
              selectedNote: selectedNote,
              selectedType: chordType,
              showOption: showOption,
              notes: notes,
              types: ["Major", "Minor"],
              onNoteChanged: (note, index) {
                setState(() {
                  selectedNote = note;
                  noteIndex = index;
                });
                _sendChordToESP32();
              },
              onTypeChanged: (type) {
                setState(() {
                  chordType = type;
                });
                _sendChordToESP32();
              },
              onShowOptionChanged: (option) {
                setState(() {
                  showOption = option;
                });
              },
            ),

            // Use the FretboardWidget for chords
            FretboardWidget(
              fretPositions: fretPositions,
              fingerPositions: fingerPositions,
              noStrumStrings: noStrumStrings,
              title: "Chord Fretboard",
              isScaleMode: false,
              selectedNote: selectedNote,
              selectedType: chordType,
              notes: chordNotes,
              currentHighlightIndex: -1, // No highlighting for chords
            ),
          ],
        ),
      ),
    );
  }
}
