# Scale BPM Synchronization Protocol

## Overview
The ESP32 hardware now supports BPM-synchronized scale display where the mobile app controls the timing and sends individual note positions as they should be highlighted.

## Protocol Design

### Characteristic Used
- **UUID**: `c3c50c29-d4a5-4998-b382-62dcc1845e12` (SCALE_PIXEL_CHAR_UUID)
- **Service**: Pixel Service

### Message Format

#### 1. Single Note Display
Send one note at a time when it should be highlighted:
```
[string, fret]
```

**Examples:**
- `[0, 3]` - Light up string 0, fret 3
- `[5, 0]` - Light up string 5, fret 0 (open string)
- `[2, 5]` - Light up string 2, fret 5

**Behavior:**
- Lights up the specified LED in **GREEN**
- Does NOT clear previous LEDs (allows multiple notes to remain lit)
- Ultra-fast response (O(1) operation)

#### 2. Clear Display
Send clear command to reset all LEDs:
```
clear
```
or
```
CLEAR
```

**Behavior:**
- Turns off all LEDs
- Use this before starting a new scale sequence

## Mobile App Implementation Guide

### Basic Flow

```dart
// 1. Clear the display before starting
await scaleCharacteristic.write(utf8.encode("clear"));

// 2. Calculate timing based on BPM
double intervalMs = (60000 / bpm); // milliseconds per beat

// 3. Loop through scale notes and send one at a time
for (var note in scaleNotes) {
  String message = "[${note.string}, ${note.fret}]";
  await scaleCharacteristic.write(utf8.encode(message));
  
  // Wait for next beat
  await Future.delayed(Duration(milliseconds: intervalMs.round()));
}

// 4. Optional: Clear at the end
await scaleCharacteristic.write(utf8.encode("clear"));
```

### Advanced: Direction Control

**Ascending:**
```dart
for (int i = 0; i < scaleNotes.length; i++) {
  sendNote(scaleNotes[i]);
  await Future.delayed(Duration(milliseconds: intervalMs));
}
```

**Descending:**
```dart
for (int i = scaleNotes.length - 1; i >= 0; i--) {
  sendNote(scaleNotes[i]);
  await Future.delayed(Duration(milliseconds: intervalMs));
}
```

**Ping-Pong (Up then Down):**
```dart
// Ascending
for (int i = 0; i < scaleNotes.length; i++) {
  sendNote(scaleNotes[i]);
  await Future.delayed(Duration(milliseconds: intervalMs));
}
// Descending (skip first note to avoid duplicate)
for (int i = scaleNotes.length - 2; i >= 0; i--) {
  sendNote(scaleNotes[i]);
  await Future.delayed(Duration(milliseconds: intervalMs));
}
```

### Visual Feedback Options

#### Option 1: Single Note Highlight (Current)
- Clear before each note
- Only one LED lit at a time
```dart
await scaleCharacteristic.write(utf8.encode("clear"));
await scaleCharacteristic.write(utf8.encode("[${note.string}, ${note.fret}]"));
```

#### Option 2: Trail Effect (Recommended)
- Don't clear between notes
- Shows progression through the scale
```dart
// Only clear at the start
await scaleCharacteristic.write(utf8.encode("clear"));

// Then just send notes without clearing
for (var note in scaleNotes) {
  await scaleCharacteristic.write(utf8.encode("[${note.string}, ${note.fret}]"));
  await Future.delayed(Duration(milliseconds: intervalMs));
}
```

#### Option 3: Fade Out Previous
- Clear after a delay to create a fade effect
```dart
sendNote(currentNote);
Future.delayed(Duration(milliseconds: intervalMs * 0.8), () {
  scaleCharacteristic.write(utf8.encode("clear"));
});
```

## Example Implementation

```dart
class ScalePracticeController {
  BLECharacteristic scaleCharacteristic;
  List<ScaleNote> scaleNotes;
  int bpm;
  bool isPlaying = false;
  
  Future<void> startScalePractice({
    required List<ScaleNote> notes,
    required int bpm,
    required Direction direction,
  }) async {
    this.scaleNotes = notes;
    this.bpm = bpm;
    isPlaying = true;
    
    double intervalMs = (60000 / bpm);
    
    // Clear display
    await scaleCharacteristic.write(utf8.encode("clear"));
    await Future.delayed(Duration(milliseconds: 100));
    
    // Determine note order based on direction
    List<ScaleNote> orderedNotes = _getOrderedNotes(direction);
    
    while (isPlaying) {
      for (var note in orderedNotes) {
        if (!isPlaying) break;
        
        // Send note to ESP32
        String message = "[${note.stringNumber}, ${note.fretNumber}]";
        await scaleCharacteristic.write(utf8.encode(message));
        
        // Wait for next beat
        await Future.delayed(Duration(milliseconds: intervalMs.round()));
      }
      
      // Optional: pause between repetitions
      await Future.delayed(Duration(milliseconds: 500));
      await scaleCharacteristic.write(utf8.encode("clear"));
      await Future.delayed(Duration(milliseconds: 500));
    }
  }
  
  void stopScalePractice() {
    isPlaying = false;
    scaleCharacteristic.write(utf8.encode("clear"));
  }
  
  List<ScaleNote> _getOrderedNotes(Direction direction) {
    switch (direction) {
      case Direction.ascending:
        return scaleNotes;
      case Direction.descending:
        return scaleNotes.reversed.toList();
      case Direction.pingPong:
        return [...scaleNotes, ...scaleNotes.reversed.skip(1).toList()];
    }
  }
}

enum Direction { ascending, descending, pingPong }

class ScaleNote {
  final int stringNumber; // 0-5
  final int fretNumber;   // 0-6
  
  ScaleNote(this.stringNumber, this.fretNumber);
}
```

## Benefits of This Approach

1. **Simple Hardware**: ESP32 just displays what it receives
2. **Flexible Timing**: Mobile app has full control over BPM
3. **Easy Direction Changes**: Logic stays in the app
4. **Responsive**: No synchronization issues
5. **Extensible**: Easy to add new patterns (random, custom sequences, etc.)

## Timing Accuracy

- **BLE Write**: ~20-50ms per message
- **LED Update**: <1ms
- **Recommended minimum BPM**: 40 (to avoid BLE congestion)
- **Recommended maximum BPM**: 200 (for comfortable timing)

## Testing Commands

Send these via BLE to test:

```
[0, 0]  -> String 0, Fret 0
[1, 2]  -> String 1, Fret 2
[2, 4]  -> String 2, Fret 4
clear   -> Clear all LEDs
```
