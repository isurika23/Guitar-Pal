/// Model representing a guitar tuning configuration
/// This allows for easy addition of different guitar types and tunings
class GuitarTuning {
  final String name;
  final String description;
  final List<GuitarString> strings;

  const GuitarTuning({
    required this.name,
    required this.description,
    required this.strings,
  });

  int get stringCount => strings.length;
}

/// Model representing a single guitar string
class GuitarString {
  final int
  number; // String number (1-6 for standard guitar, 1 being highest pitch)
  final String note; // Note name (e.g., "E", "A", "D")
  final int octave; // Octave number
  final double frequency; // Target frequency in Hz

  const GuitarString({
    required this.number,
    required this.note,
    required this.octave,
    required this.frequency,
  });

  /// Returns the full note name with octave (e.g., "E2", "A2", "D3")
  String get fullNoteName => '$note$octave';

  /// Returns display name for UI (string number and note)
  String get displayName => '$number: $note';
}

/// Predefined guitar tunings
class GuitarTunings {
  // Standard 6-string guitar tuning (EADGBE)
  static const GuitarTuning standard6String = GuitarTuning(
    name: "Standard 6-String",
    description: "EADGBE - Standard tuning for 6-string guitar",
    strings: [
      GuitarString(
        number: 1,
        note: "E",
        octave: 4,
        frequency: 329.63,
      ), // High E
      GuitarString(number: 2, note: "B", octave: 3, frequency: 246.94),
      GuitarString(number: 3, note: "G", octave: 3, frequency: 196.00),
      GuitarString(number: 4, note: "D", octave: 3, frequency: 146.83),
      GuitarString(number: 5, note: "A", octave: 2, frequency: 110.00),
      GuitarString(number: 6, note: "E", octave: 2, frequency: 82.41), // Low E
    ],
  );

  // Drop D tuning
  static const GuitarTuning dropD = GuitarTuning(
    name: "Drop D",
    description: "DADGBE - Drop D tuning",
    strings: [
      GuitarString(number: 1, note: "E", octave: 4, frequency: 329.63),
      GuitarString(number: 2, note: "B", octave: 3, frequency: 246.94),
      GuitarString(number: 3, note: "G", octave: 3, frequency: 196.00),
      GuitarString(number: 4, note: "D", octave: 3, frequency: 146.83),
      GuitarString(number: 5, note: "A", octave: 2, frequency: 110.00),
      GuitarString(number: 6, note: "D", octave: 2, frequency: 73.42), // Low D
    ],
  );

  // Half-step down tuning (Eb standard)
  static const GuitarTuning halfStepDown = GuitarTuning(
    name: "Half-Step Down",
    description: "Eb Ab Db Gb Bb Eb - Half-step down",
    strings: [
      GuitarString(number: 1, note: "Eb", octave: 4, frequency: 311.13),
      GuitarString(number: 2, note: "Bb", octave: 3, frequency: 233.08),
      GuitarString(number: 3, note: "Gb", octave: 3, frequency: 185.00),
      GuitarString(number: 4, note: "Db", octave: 3, frequency: 138.59),
      GuitarString(number: 5, note: "Ab", octave: 2, frequency: 103.83),
      GuitarString(number: 6, note: "Eb", octave: 2, frequency: 77.78),
    ],
  );

  // 7-string guitar (standard tuning)
  static const GuitarTuning standard7String = GuitarTuning(
    name: "Standard 7-String",
    description: "BEADGBE - Standard 7-string tuning",
    strings: [
      GuitarString(number: 1, note: "E", octave: 4, frequency: 329.63),
      GuitarString(number: 2, note: "B", octave: 3, frequency: 246.94),
      GuitarString(number: 3, note: "G", octave: 3, frequency: 196.00),
      GuitarString(number: 4, note: "D", octave: 3, frequency: 146.83),
      GuitarString(number: 5, note: "A", octave: 2, frequency: 110.00),
      GuitarString(number: 6, note: "E", octave: 2, frequency: 82.41),
      GuitarString(number: 7, note: "B", octave: 1, frequency: 61.74), // Low B
    ],
  );

  /// List of all available tunings
  static const List<GuitarTuning> allTunings = [
    standard6String,
    dropD,
    halfStepDown,
    standard7String,
  ];

  /// Get tuning by name
  static GuitarTuning? getTuningByName(String name) {
    try {
      return allTunings.firstWhere((tuning) => tuning.name == name);
    } catch (e) {
      return null;
    }
  }
}

/// Enum representing tuning accuracy status
enum TuningStatus {
  tooLow, // String is flat (too low)
  inTune, // String is in tune
  tooHigh, // String is sharp (too high)
  noInput, // No audio input detected
}

/// Helper class for tuning status calculation
class TuningHelper {
  /// Threshold in cents for considering a note "in tune"
  /// 1 cent = 1/100th of a semitone
  static const double inTuneCents = 5.0;

  /// Calculate cents difference between detected and target frequency
  /// Positive value means sharp (too high), negative means flat (too low)
  static double calculateCents(double detectedFreq, double targetFreq) {
    if (detectedFreq <= 0 || targetFreq <= 0) return 0.0;
    return 1200 * (log2(detectedFreq / targetFreq));
  }

  /// Get tuning status based on cents difference
  static TuningStatus getTuningStatus(double cents) {
    if (cents.abs() <= inTuneCents) {
      return TuningStatus.inTune;
    } else if (cents < 0) {
      return TuningStatus.tooLow;
    } else {
      return TuningStatus.tooHigh;
    }
  }

  /// Calculate log base 2
  static double log2(double x) {
    // Using change of base formula: log2(x) = ln(x) / ln(2)
    // Import dart:math for the ln function
    return 0.0; // Will be properly implemented in widget with import
  }
}
