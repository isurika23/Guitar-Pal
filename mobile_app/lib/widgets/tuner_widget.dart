import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/guitar_tuning.dart';
import '../services/bluetooth_service.dart';
import '../services/pitch_detector_service.dart';

/// Guitar Tuner Widget
/// Provides chromatic tuning for various guitar configurations
class TunerPage extends StatefulWidget {
  final ESP32BluetoothService bluetoothService;

  const TunerPage({required this.bluetoothService, Key? key}) : super(key: key);

  @override
  _TunerPageState createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  // Current selected tuning
  GuitarTuning selectedTuning = GuitarTunings.standard6String;

  // Currently selected string (null means chromatic mode)
  GuitarString? selectedString;

  // Detected frequency from audio input
  double detectedFrequency = 0.0;

  // Audio amplitude
  double amplitude = 0.0;

  // Pitch detector service
  final PitchDetectorService _pitchDetector = PitchDetectorService();

  // Stream subscriptions
  StreamSubscription<double>? _frequencySubscription;
  StreamSubscription<double>? _amplitudeSubscription;

  // Tuning mode
  bool isAutoMode = true; // Auto-detect string vs manual selection

  // Service initialized flag
  bool _isInitialized = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializePitchDetector();
  }

  @override
  void dispose() {
    _frequencySubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _pitchDetector.dispose();
    super.dispose();
  }

  /// Initialize pitch detector service
  Future<void> _initializePitchDetector() async {
    if (_isInitializing || _isInitialized) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      bool success = await _pitchDetector.initialize();

      if (success && mounted) {
        // Subscribe to frequency stream
        _frequencySubscription = _pitchDetector.frequencyStream.listen((freq) {
          if (mounted) {
            setState(() {
              detectedFrequency = freq;

              // Auto-detect string in auto mode
              if (isAutoMode && freq > 0) {
                _autoDetectString(freq);
              }
            });
          }
        });

        // Subscribe to amplitude stream
        _amplitudeSubscription = _pitchDetector.amplitudeStream.listen((amp) {
          if (mounted) {
            setState(() {
              amplitude = amp;
            });
          }
        });

        // Start listening immediately
        await _pitchDetector.startListening();

        setState(() {
          _isInitialized = true;
          _isInitializing = false;
        });
      } else {
        setState(() {
          _isInitializing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Microphone permission denied. Please enable it in settings.',
              ),
              action: SnackBarAction(label: 'OK', onPressed: () {}),
            ),
          );
        }
      }
    } catch (e) {
      print('Error initializing pitch detector: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  /// Auto-detect which string is being played based on frequency
  void _autoDetectString(double frequency) {
    if (frequency <= 0) return;

    // Find the closest string in the current tuning
    GuitarString? closest;
    double smallestDiff = double.infinity;

    for (var string in selectedTuning.strings) {
      double diff = (frequency - string.frequency).abs();

      // Within 50 Hz range (about 2 semitones)
      if (diff < 50 && diff < smallestDiff) {
        smallestDiff = diff;
        closest = string;
      }
    }

    if (closest != null && selectedString != closest) {
      setState(() {
        selectedString = closest;
      });
    }
  }

  /// Toggle audio listening
  Future<void> _toggleListening() async {
    if (_pitchDetector.isListening) {
      await _pitchDetector.stopListening();
    } else {
      await _pitchDetector.startListening();
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// Calculate cents difference from target frequency
  double _calculateCents(double targetFreq) {
    if (detectedFrequency <= 0 || targetFreq <= 0) return 0.0;
    return 1200 * (log(detectedFrequency / targetFreq) / ln2);
  }

  /// Get tuning status
  TuningStatus _getTuningStatus(double cents) {
    if (detectedFrequency == 0.0) return TuningStatus.noInput;
    if (cents.abs() <= 5.0) return TuningStatus.inTune;
    if (cents < 0) return TuningStatus.tooLow;
    return TuningStatus.tooHigh;
  }

  /// Get color based on tuning status
  Color _getStatusColor(TuningStatus status) {
    switch (status) {
      case TuningStatus.inTune:
        return Colors.green;
      case TuningStatus.tooLow:
        return Colors.red;
      case TuningStatus.tooHigh:
        return Colors.orange;
      case TuningStatus.noInput:
        return Colors.grey;
    }
  }

  /// Get status text
  String _getStatusText(TuningStatus status, double cents) {
    switch (status) {
      case TuningStatus.inTune:
        return "IN TUNE ✓";
      case TuningStatus.tooLow:
        return "TOO LOW (${cents.toStringAsFixed(1)}¢)";
      case TuningStatus.tooHigh:
        return "TOO HIGH (+${cents.toStringAsFixed(1)}¢)";
      case TuningStatus.noInput:
        return "WAITING FOR INPUT...";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8),
            // Title with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.green[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.music_note, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Guitar Tuner",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      "Professional Precision",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),

            // Listening Control Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isInitialized ? _toggleListening : null,
                icon: Icon(
                  _pitchDetector.isListening ? Icons.mic : Icons.mic_off,
                  size: 24,
                ),
                label: Text(
                  _pitchDetector.isListening
                      ? 'Listening...'
                      : 'Start Listening',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pitchDetector.isListening
                      ? Colors.red[400]
                      : Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
              ),
            ),

            // Amplitude indicator
            if (_pitchDetector.isListening && amplitude > 0) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.graphic_eq, size: 18, color: Colors.blue[700]),
                    SizedBox(width: 8),
                    Text(
                      'Signal: ${(amplitude * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 100,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: amplitude.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green, Colors.blue],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 24),

            // Tuning Selection - Enhanced
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, color: Colors.green[700], size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Select Tuning",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.green[50],
                      ),
                      child: DropdownButton<GuitarTuning>(
                        value: selectedTuning,
                        isExpanded: true,
                        underline: SizedBox(),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.green[700],
                        ),
                        dropdownColor: Colors.white,
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        menuMaxHeight: 450,
                        style: TextStyle(color: Colors.grey[850], fontSize: 15),
                        items: GuitarTunings.allTunings.map((tuning) {
                          bool isSelected = tuning == selectedTuning;
                          return DropdownMenuItem(
                            value: tuning,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          Colors.green[50]!,
                                          Colors.green[100]!,
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    // Icon indicator for selected item
                                    Container(
                                      width: 4,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.green[600]
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    // Tuning info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              if (isSelected)
                                                Container(
                                                  margin: EdgeInsets.only(
                                                    right: 6,
                                                  ),
                                                  padding: EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[600],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.check,
                                                    size: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              Expanded(
                                                child: Text(
                                                  tuning.name,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.w900
                                                        : FontWeight.bold,
                                                    fontSize: 15,
                                                    color: isSelected
                                                        ? Colors.green[800]
                                                        : Colors.grey[800],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 1),
                                          Text(
                                            tuning.description,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSelected
                                                  ? Colors.green[700]
                                                  : Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // String count badge
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.green[600]
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "${tuning.stringCount} str",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (tuning) {
                          if (tuning != null) {
                            setState(() {
                              selectedTuning = tuning;
                              // Reset to first string when changing tuning
                              if (selectedString != null) {
                                selectedString = tuning.strings.first;
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Mode Selection - Enhanced with toggle buttons
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_input_antenna,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Tuning Mode",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModeButton(
                            icon: Icons.auto_awesome,
                            label: "Auto",
                            subtitle: "Detect",
                            isSelected: isAutoMode,
                            onTap: () {
                              setState(() {
                                isAutoMode = true;
                                selectedString = null;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildModeButton(
                            icon: Icons.touch_app,
                            label: "Manual",
                            subtitle: "Select",
                            isSelected: !isAutoMode,
                            onTap: () {
                              setState(() {
                                isAutoMode = false;
                                if (selectedString == null) {
                                  selectedString = selectedTuning.strings.first;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Tuning Display
            if (selectedString != null) ...[
              _buildTuningDisplay(),
              SizedBox(height: 16),
            ],

            // String Selection (Manual Mode) - Enhanced
            if (!isAutoMode)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_list_numbered,
                            color: Colors.purple[700],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Select String to Tune",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ...selectedTuning.strings.map((string) {
                        bool isSelected = selectedString == string;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  selectedString = string;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            Colors.green[400]!,
                                            Colors.green[600]!,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.green[700]!
                                        : Colors.grey[200]!,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0.9),
                                                  Colors.white.withOpacity(0.7),
                                                ],
                                              )
                                            : LinearGradient(
                                                colors: [
                                                  Colors.green[300]!,
                                                  Colors.green[500]!,
                                                ],
                                              ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          string.number.toString(),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.green[700]
                                                : Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            string.fullNoteName,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            "${string.frequency.toStringAsFixed(2)} Hz",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isSelected
                                                  ? Colors.white.withOpacity(
                                                      0.9,
                                                    )
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.green[600],
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

            // Instructions for Auto Mode - Enhanced
            if (isAutoMode)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.cyan[50]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Auto Detection Mode",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Enable the microphone, play any string, and the tuner will automatically detect and display which string you're tuning using real-time pitch detection.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[800],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            // Quick Reference - Enhanced
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: Colors.indigo[700],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "String Reference",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      selectedTuning.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 16),
                    ...selectedTuning.strings.map((string) {
                      bool isCurrent = selectedString == string;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Colors.green[50]
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent
                                  ? Colors.green[300]!
                                  : Colors.grey[200]!,
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isCurrent
                                        ? [
                                            Colors.green[400]!,
                                            Colors.green[600]!,
                                          ]
                                        : [
                                            Colors.grey[300]!,
                                            Colors.grey[400]!,
                                          ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    string.number.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  string.fullNoteName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent
                                        ? Colors.green[800]
                                        : Colors.grey[800],
                                  ),
                                ),
                              ),
                              Text(
                                "${string.frequency.toStringAsFixed(2)} Hz",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isCurrent
                                      ? Colors.green[700]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build mode selection button
  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[800],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the main tuning display widget - Enhanced
  Widget _buildTuningDisplay() {
    if (selectedString == null) return SizedBox.shrink();

    double cents = _calculateCents(selectedString!.frequency);
    TuningStatus status = _getTuningStatus(cents);
    Color statusColor = _getStatusColor(status);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            // Current String Label with badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        selectedString!.number.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "String ${selectedString!.number}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Target Note - Large and prominent
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    statusColor.withOpacity(0.1),
                    statusColor.withOpacity(0.05),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Text(
                selectedString!.fullNoteName,
                style: TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                  letterSpacing: -2,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Target Frequency
            Text(
              "Target: ${selectedString!.frequency.toStringAsFixed(2)} Hz",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            // Detected Frequency
            if (detectedFrequency > 0) ...[
              SizedBox(height: 4),
              Text(
                "Current: ${detectedFrequency.toStringAsFixed(2)} Hz",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            SizedBox(height: 24),

            // Tuning Meter
            _buildTuningMeter(cents, status),

            SizedBox(height: 24),

            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withOpacity(0.8), statusColor],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status == TuningStatus.inTune)
                    Icon(Icons.check_circle, color: Colors.white, size: 24),
                  if (status == TuningStatus.tooLow)
                    Icon(Icons.arrow_downward, color: Colors.white, size: 24),
                  if (status == TuningStatus.tooHigh)
                    Icon(Icons.arrow_upward, color: Colors.white, size: 24),
                  if (status == TuningStatus.noInput)
                    Icon(Icons.hearing, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    _getStatusText(status, cents),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the visual tuning meter - Enhanced with better visuals
  Widget _buildTuningMeter(double cents, TuningStatus status) {
    // Clamp cents to reasonable display range (-50 to +50)
    double displayCents = cents.clamp(-50.0, 50.0);
    double normalizedPosition = (displayCents + 50) / 100; // 0 to 1

    return Column(
      children: [
        // Cent value display
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.straighten, size: 16, color: Colors.grey[700]),
              SizedBox(width: 6),
              Text(
                cents.abs() < 0.5
                    ? "0.0¢"
                    : "${cents > 0 ? '+' : ''}${cents.toStringAsFixed(1)}¢",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Meter bar with enhanced design
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Colored sections with gradient
              Row(
                children: [
                  // Too low (red zone)
                  Expanded(
                    flex: 45,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.4),
                            Colors.red.withOpacity(0.2),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          bottomLeft: Radius.circular(40),
                        ),
                      ),
                    ),
                  ),
                  // In tune (green zone)
                  Expanded(
                    flex: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.5),
                            Colors.green.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Too high (orange zone)
                  Expanded(
                    flex: 45,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.2),
                            Colors.orange.withOpacity(0.4),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Center target line
              Center(
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                ),
              ),

              // Indicator needle with glow effect
              if (status != TuningStatus.noInput)
                Positioned(
                  left:
                      (MediaQuery.of(context).size.width - 96) *
                      normalizedPosition,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(status).withOpacity(0.8),
                          _getStatusColor(status),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(status).withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        SizedBox(height: 12),

        // Labels with icons
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.remove, color: Colors.red, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "FLAT",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green[700], size: 16),
                    SizedBox(width: 4),
                    Text(
                      "IN TUNE",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    "SHARP",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.add, color: Colors.orange, size: 16),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
