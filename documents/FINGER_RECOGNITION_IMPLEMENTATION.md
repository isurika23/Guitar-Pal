# Finger Recognition and Wrong Position Alerting System

## Overview
This document describes the implementation of a real-time finger recognition and wrong position alerting system for the Guitar-Pal project. The system detects incorrect finger placements on the guitar fretboard and provides visual feedback to the user via red circles in the mobile app.

## Hardware Implementation (ESP32)

### GPIO Pin Configuration

#### String Output Pins (6 pins)
These pins are energized ONE AT A TIME to detect which fret is being pressed on each string:
- **String 0** (thinnest): GPIO 32
- **String 1**: GPIO 33
- **String 2**: GPIO 25
- **String 3**: GPIO 26
- **String 4**: GPIO 27
- **String 5** (thickest): GPIO 13

**Configuration**: OUTPUT pins, initially LOW

#### Fret Input Pins (6 pins)
These pins read the state of each fret (1-6). Fret 0 represents an open string (no physical connection needed).
- **Fret 1**: GPIO 15
- **Fret 2**: GPIO 16
- **Fret 3**: GPIO 17
- **Fret 4**: GPIO 18
- **Fret 5**: GPIO 19
- **Fret 6**: GPIO 21

**Configuration**: INPUT pins with **10kΩ pull-down resistors** (external hardware)

### Hardware Connection Diagram
```
String Pins (OUTPUT)          Fret Pins (INPUT with 10k pull-down)
    GPIO 32 ──────┐              GPIO 15 (Fret 1)
    GPIO 33 ──────┤              GPIO 16 (Fret 2)
    GPIO 25 ──────┤              GPIO 17 (Fret 3)
    GPIO 26 ──────┤──> Guitar    GPIO 18 (Fret 4)
    GPIO 27 ──────┤   Fretboard  GPIO 19 (Fret 5)
    GPIO 13 ──────┘              GPIO 21 (Fret 6)
                                     │
                                    GND via 10kΩ resistor
```

### Scanning Algorithm

The ESP32 uses a **time-multiplexed scanning** approach:

1. **Initialize**: Set all string pins LOW
2. **For each string** (0-5):
   - Set current string pin HIGH
   - Wait 100μs for signal stabilization
   - Read all 6 fret input pins
   - If any fret pin is HIGH, record that fret number for this string
   - Set current string pin LOW
   - Wait 50μs before next string
3. **Compare** detected positions with expected chord positions
4. **Transmit** wrong position data via BLE if discrepancies found

**Scan Frequency**: Every 200ms (5 Hz) for responsive real-time feedback

### Detection Logic

The system compares detected finger positions against expected chord positions:

| Expected Value | Meaning | Wrong Condition |
|---------------|---------|-----------------|
| -1 | Muted/No Strum | Any fret detected (finger pressing) |
| 0 | Open String | Any fret detected (finger pressing) |
| 1-6 | Specific Fret | Wrong fret detected OR no fret detected |

### BLE Characteristic

**UUID**: `c3c50c29-d4a5-4998-b382-62dcc1845e14`

**Type**: Notify (one-way from ESP32 to mobile app)

**Data Format**: JSON array of wrong position pairs
```
[[string, fret], [string, fret], ...]
```

**Examples**:
- `[]` - No wrong positions (all correct)
- `[[0, 1]]` - String 0, Fret 1 is wrong
- `[[2, 0], [3, 3]]` - String 2 (open) and String 3, Fret 3 are wrong

### Key Functions

#### `setupFingerDetection()`
- Initializes GPIO pins
- Configures string pins as OUTPUT (LOW)
- Configures fret pins as INPUT

#### `scanFingerPositions()`
- Scans all string/fret combinations
- Stores detected positions in `detectedFretPos[]` array
- Uses time multiplexing to avoid cross-talk

#### `checkFingerPositions()`
- Compares detected positions with expected positions
- Returns `true` if wrong positions found
- Updates `wrongPositions[]` boolean array

#### `getWrongPositionsData()`
- Generates JSON string of wrong positions
- Format: `[[string, fret], [string, fret], ...]`

#### `sendWrongPositions(String data)`
- Sends wrong position data via BLE notification
- Only sends when data changes (reduces BLE traffic)

#### `updateExpectedPositions(int* frets, int* fingers)`
- Called when new chord is selected in mobile app
- Updates `expectedFretPos[]` and `expectedFingerPos[]` arrays

## Mobile App Implementation (Flutter/Dart)

### Bluetooth Service Updates

#### New Stream Controller
```dart
final StreamController<List<List<int>>> _wrongPositionsController =
    StreamController<List<List<int>>>.broadcast();
```

#### New Stream Getter
```dart
Stream<List<List<int>>> get wrongPositionsStream =>
    _wrongPositionsController.stream;
```

#### Wrong Position Characteristic
**UUID**: `c3c50c29-d4a5-4998-b382-62dcc1845e14`

The service automatically:
1. Discovers the wrong position characteristic during connection
2. Enables notifications
3. Parses incoming data format: `"[[0,1],[2,3]]"`
4. Emits parsed data to `wrongPositionsStream`

### FretboardWidget Updates

#### New Parameter
```dart
final List<List<int>>? wrongPositions;
```

#### Red Circle Rendering
Wrong positions are drawn as **red stroke circles** (opacity 0.7) on top of the fretboard:
- **Stroke width**: 4.0
- **Radius**: 18 (slightly larger than normal finger circles)
- **Color**: Red with 70% opacity
- **Position**: Centered on the detected wrong position

#### Rendering Priority
1. Fretboard grid (strings, frets, nut)
2. Chord/scale positions (filled circles with colors)
3. **Wrong positions (red circles)** - drawn LAST to appear on top

### Chord Practice Widget Updates

#### State Variables
```dart
List<List<int>> wrongPositions = [];
StreamSubscription<List<List<int>>>? _wrongPositionsSubscription;
```

#### Lifecycle Management
- **`initState()`**: Sets up wrong position listener
- **`dispose()`**: Cancels subscription and clears display
- **Real-time updates**: UI rebuilds whenever wrong positions change

#### Integration
```dart
FretboardWidget(
  fretPositions: fretPositions,
  fingerPositions: fingerPositions,
  wrongPositions: wrongPositions, // Real-time wrong position data
  // ... other parameters
)
```

## User Experience Flow

1. **User selects a chord** (e.g., C Major) in the mobile app
2. **Mobile app sends** chord data to ESP32 via BLE
3. **ESP32 updates** expected finger positions in memory
4. **LED display shows** correct finger positions with colors
5. **User places fingers** on the guitar fretboard
6. **ESP32 continuously scans** (every 200ms) for finger positions
7. **ESP32 compares** detected vs expected positions
8. **If wrong positions detected**:
   - ESP32 sends wrong position data via BLE notification
   - Mobile app receives data
   - **Red circles appear** on fretboard widget showing wrong positions
9. **If all positions correct**:
   - ESP32 sends empty array `[]`
   - Red circles disappear from mobile app

## Testing Procedure

### Hardware Testing
1. **Open String Test**:
   - Select chord with open string (fret = 0)
   - Press any fret on that string → Red circle should appear
   
2. **Muted String Test**:
   - Select chord with muted string (fret = -1)
   - Press any fret on that string → Red circle should appear

3. **Wrong Fret Test**:
   - Select chord requiring Fret 3
   - Press Fret 2 or Fret 4 → Red circle should appear on pressed fret

4. **Correct Position Test**:
   - Place all fingers correctly → No red circles

### Mobile App Testing
1. **Connection Test**: Verify wrong position characteristic is discovered
2. **Real-time Update Test**: Wrong positions update immediately (<300ms)
3. **Visual Feedback Test**: Red circles appear at correct fretboard positions
4. **Clear Test**: Red circles disappear when fingers placed correctly

## Configuration Parameters

### Timing
- **Scan interval**: 200ms (adjustable in `loop()`)
- **Signal stabilization delay**: 100μs after energizing string
- **Inter-string delay**: 50μs between string scans

### Thresholds
- **Digital HIGH threshold**: ESP32 default (~2.0V)
- **Pull-down resistor**: 10kΩ (prevents floating inputs)

### Visual Feedback
- **Wrong position circle radius**: 18px
- **Wrong position color**: Red (#FF0000, 70% opacity)
- **Stroke width**: 4.0px

## Troubleshooting

### No Wrong Position Detection
- Check GPIO pin connections (string outputs and fret inputs)
- Verify 10kΩ pull-down resistors on fret inputs
- Check Serial Monitor for "Wrong position on string X" messages
- Verify BLE connection and characteristic discovery

### False Positives
- Increase signal stabilization delay (currently 100μs)
- Check for electrical noise or crosstalk between strings
- Verify pull-down resistors are properly grounded

### Delayed Updates
- Reduce scan interval (currently 200ms)
- Check BLE connection quality
- Verify `shouldRepaint()` includes `wrongPositions` check

### Red Circles Not Appearing
- Check `wrongPositionsStream` in debugger
- Verify `FretboardWidget` receives `wrongPositions` parameter
- Check Flutter console for parsing errors

## Performance Considerations

### ESP32
- **CPU usage**: <5% (scanning is efficient)
- **Memory usage**: ~100 bytes for tracking arrays
- **BLE traffic**: Minimal (only sends when positions change)

### Mobile App
- **UI updates**: Only when wrong positions change (efficient)
- **Memory**: Negligible overhead
- **Battery impact**: Minimal (BLE notifications only)

## Future Enhancements

1. **Haptic Feedback**: Vibrate phone when wrong position detected
2. **Audio Feedback**: Play error sound for wrong positions
3. **Position Strength**: Show HOW wrong (distance from correct fret)
4. **Multi-chord Practice**: Track progress across multiple chords
5. **Difficulty Levels**: Adjust sensitivity for beginners vs advanced
6. **Statistics**: Track common mistake patterns

## Files Modified

### Hardware (ESP32)
- `hardware/include/main.h` - GPIO pin definitions, function declarations
- `hardware/src/main.cpp` - Scanning logic, detection functions
- `hardware/include/bluetooth.h` - Wrong position characteristic UUID
- `hardware/src/bluetooth.cpp` - BLE notification handling

### Mobile App (Flutter)
- `mobile_app/lib/services/bluetooth_service.dart` - Wrong position stream
- `mobile_app/lib/widgets/fret_board_widget.dart` - Red circle rendering
- `mobile_app/lib/widgets/chord_practice_widget.dart` - Stream subscription

## Implementation Summary

This implementation provides a robust, real-time finger position recognition system that:
- ✅ Uses hardware GPIO scanning for accurate detection
- ✅ Provides immediate visual feedback (<300ms latency)
- ✅ Handles open strings, muted strings, and fretted positions
- ✅ Minimizes BLE traffic (only sends changes)
- ✅ Integrates seamlessly with existing chord display system
- ✅ Extensible for future enhancements (scales, exercises, etc.)

The system enhances the learning experience by providing **real-time corrective feedback**, helping users develop proper finger placement habits for guitar playing.
