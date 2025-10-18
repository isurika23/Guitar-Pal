import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _loadScaleData();
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
        print(scaleData);
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

        // Convert positions to string for ESP32 transmission
        String positionsString = positions.toString();

        // Log the complete scale information
        String scaleJsonString = json.encode(scaleMessage);
        print("Complete scale data: $scaleJsonString");
        print(
          "Sending scale positions to ESP32 scale pixel characteristic: $positionsString",
        );

        // Send scale positions specifically to scale pixel characteristic
        // This targets the _scalePixelCharUUID in _pixelServiceUUID service
        widget.bluetoothService.sendScaleData(positionsString);
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

            // Use the FretboardWidget for scales
            FretboardWidget(
              fretPositions: [], // Not used for scales
              title: "Scale Fretboard",
              isScaleMode: true,
              scalePositions: scalePositions,
              selectedNote: selectedNote,
              selectedType: scaleType,
              notes: scaleNotes,
            ),
          ],
        ),
      ),
    );
  }
}
