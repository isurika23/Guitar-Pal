import 'dart:async';
import 'dart:math';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for detecting pitch from audio input
class PitchDetectorService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  StreamController<double>? _frequencyController;
  StreamController<double>? _amplitudeController;
  bool _isListening = false;
  Timer? _recordingTimer;

  /// Stream of detected frequencies (in Hz)
  Stream<double> get frequencyStream => _frequencyController!.stream;

  /// Stream of audio amplitude (volume level)
  Stream<double> get amplitudeStream => _amplitudeController!.stream;

  /// Whether the service is currently listening
  bool get isListening => _isListening;

  /// Initialize the pitch detector service
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          print('Microphone permission denied');
          return false;
        }
      }

      // Initialize stream controllers
      _frequencyController = StreamController<double>.broadcast();
      _amplitudeController = StreamController<double>.broadcast();

      return true;
    } catch (e) {
      print('Error initializing pitch detector: $e');
      return false;
    }
  }

  /// Start listening to audio input
  Future<void> startListening() async {
    if (_isListening) return;

    try {
      // Check if we have microphone permission
      if (!await _audioRecorder.hasPermission()) {
        print('No microphone permission');
        return;
      }

      // Start recording with stream
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );

      _isListening = true;

      // Process audio stream
      stream.listen(
        (data) {
          _processAudioData(data);
        },
        onError: (error) {
          print('Error in audio stream: $error');
          stopListening();
        },
        onDone: () {
          print('Audio stream ended');
          _isListening = false;
        },
      );
    } catch (e) {
      print('Error starting audio recording: $e');
      _isListening = false;
    }
  }

  /// Process raw audio data to detect pitch
  void _processAudioData(List<int> rawData) {
    try {
      // Convert raw bytes to double samples
      List<double> audioSamples = [];
      for (int i = 0; i < rawData.length - 1; i += 2) {
        // Combine two bytes into 16-bit PCM sample
        int sample = rawData[i] | (rawData[i + 1] << 8);
        // Convert to signed integer
        if (sample > 32767) sample -= 65536;
        // Normalize to -1.0 to 1.0
        audioSamples.add(sample / 32768.0);
      }

      if (audioSamples.isEmpty) return;

      // Calculate amplitude (RMS)
      double sumSquares = 0;
      for (var sample in audioSamples) {
        sumSquares += sample * sample;
      }
      double amplitude = sqrt(sumSquares / audioSamples.length);

      // Only process if amplitude is above threshold (noise gate)
      const double amplitudeThreshold = 0.01;
      if (amplitude < amplitudeThreshold) {
        _frequencyController?.add(0.0);
        _amplitudeController?.add(amplitude);
        return;
      }

      // Detect pitch using autocorrelation
      final pitch = _detectPitchAutocorrelation(audioSamples, 44100);

      if (pitch > 0 && pitch < 2000) {
        // Filter out unrealistic frequencies
        _frequencyController?.add(pitch);
      } else {
        _frequencyController?.add(0.0);
      }

      _amplitudeController?.add(amplitude);
    } catch (e) {
      print('Error processing audio data: $e');
    }
  }

  /// Detect pitch using autocorrelation method (YIN algorithm simplified)
  double _detectPitchAutocorrelation(List<double> samples, int sampleRate) {
    if (samples.length < 2048) return 0.0;

    const int minPeriod = 40; // ~1100 Hz max
    const int maxPeriod = 2000; // ~22 Hz min

    // Use only first 2048 samples for efficiency
    final buffer = samples.sublist(0, min(2048, samples.length));

    // Autocorrelation
    double bestCorrelation = 0.0;
    int bestPeriod = 0;

    for (int lag = minPeriod; lag < min(maxPeriod, buffer.length ~/ 2); lag++) {
      double correlation = 0.0;
      for (int i = 0; i < buffer.length - lag; i++) {
        correlation += buffer[i] * buffer[i + lag];
      }

      if (correlation > bestCorrelation) {
        bestCorrelation = correlation;
        bestPeriod = lag;
      }
    }

    if (bestPeriod == 0) return 0.0;

    // Convert period to frequency
    double frequency = sampleRate / bestPeriod;

    return frequency;
  }

  /// Stop listening to audio input
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _audioRecorder.stop();
      _isListening = false;
      _recordingTimer?.cancel();
      _frequencyController?.add(0.0);
    } catch (e) {
      print('Error stopping audio recording: $e');
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await stopListening();
    await _audioRecorder.dispose();
    await _frequencyController?.close();
    await _amplitudeController?.close();
  }

  /// Find closest note to a given frequency
  static String getClosestNote(double frequency) {
    if (frequency <= 0) return '';

    // A4 = 440 Hz
    const double a4Frequency = 440.0;
    const int a4MidiNote = 69;

    // Calculate MIDI note number
    double midiNote = 12 * (log(frequency / a4Frequency) / ln2) + a4MidiNote;
    int closestMidi = midiNote.round();

    // Note names
    const List<String> noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];

    int noteIndex = closestMidi % 12;
    int octave = (closestMidi ~/ 12) - 1;

    return '${noteNames[noteIndex]}$octave';
  }

  /// Calculate frequency for a given note
  static double getNoteFrequency(String note, int octave) {
    const List<String> noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];

    int noteIndex = noteNames.indexOf(note);
    if (noteIndex == -1) return 0.0;

    int midiNote = (octave + 1) * 12 + noteIndex;

    // A4 = 440 Hz (MIDI note 69)
    return 440.0 * pow(2, (midiNote - 69) / 12.0);
  }

  /// Calculate cents difference between two frequencies
  static double calculateCents(double frequency, double targetFrequency) {
    if (frequency <= 0 || targetFrequency <= 0) return 0.0;
    return 1200 * (log(frequency / targetFrequency) / ln2);
  }
}
