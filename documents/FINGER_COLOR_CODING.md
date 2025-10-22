# Finger-Based Color Coding Implementation

## Overview
This document describes the implementation of finger-based color coding for chord display on the Guitar-Pal LED fretboard. The system now sends both fret positions and finger positions via Bluetooth and displays them with distinct colors for each finger.

## Implementation Details

### 1. Mobile App Changes

#### `bluetooth_service.dart`
- **Modified Method**: `sendChordData(String fretPositions, [String? fingerPositions])`
- **Data Format**: `"[fret1,...,fret6]|[finger1,...,finger6]"`
- **Example**: `"[-1, 3, 2, 0, 1, 0]|[-1, 3, 2, -1, 1, -1]"`

The method now accepts an optional `fingerPositions` parameter and combines both fret and finger data using a pipe (`|`) separator for efficient parsing on the ESP32 side.

#### `chord_practice_widget.dart`
- Extracts both `fret_num` and `finger_pos` from the chord JSON data
- Sends both arrays to the Bluetooth service
- Example call: `bluetoothService.sendChordData(fretPosString, fingerPosString)`

### 2. Hardware Changes

#### `data_handling.h` & `data_handling.cpp`
- **New Function**: `parseChordCommandWithFingers()`
- **Time Complexity**: O(n) where n is the string length
- **Algorithm**:
  1. Single pass to find pipe separator
  2. Split into fret and finger portions
  3. Parse each portion using existing `parseChordCommand()` function
  4. Validate both arrays have matching lengths

#### `bluetooth.cpp`
- Updated `ChordPixelCharacteristicCallbacks` to use new parsing function
- Calls `convertChordPositionsToPixelsWithFingers()` instead of old method

#### `pixel_mapping.h` & `pixel_mapping.cpp`
- **New Function**: `convertChordPositionsToPixelsWithFingers()`
- **Time Complexity**: O(1) - processes fixed 6 strings
- **Features**:
  - Maintains existing behavior for open strings (green) and no-strum strings (red)
  - Adds finger-specific colors for pressed frets

## Color Scheme

| Condition | Color | RGB | Usage |
|-----------|-------|-----|-------|
| Open string (fret = 0) | GREEN | (0, 255, 0) | Entire column |
| No strum (fret < 0) | RED | (255, 0, 0) | Entire column |
| Finger 1 | BLUE | (0, 0, 255) | Pressed fret |
| Finger 2 | CYAN | (0, 255, 255) | Pressed fret |
| Finger 3 | YELLOW | (255, 255, 0) | Pressed fret |
| Finger 4 | ORANGE | (255, 165, 0) | Pressed fret |
| No finger info | WHITE | (255, 255, 255) | Fallback |

### Color Selection Rationale
- **Avoided**: Green (open strings) and Red (no-strum)
- **Selected**: High contrast, easily distinguishable colors
- **Benefits**: 
  - Clear visual distinction between fingers
  - Easy to learn and remember
  - Works well on LED strips

## Data Flow

```
Mobile App (chord_practice_widget.dart)
    ↓
Extract fret_num and finger_pos from JSON
    ↓
Convert to string format: "[f1,f2,...,f6]" and "[fp1,fp2,...,fp6]"
    ↓
Bluetooth Service (sendChordData)
    ↓
Combine: "[f1,f2,...,f6]|[fp1,fp2,...,fp6]"
    ↓
Send via BLE to ESP32 Chord Characteristic
    ↓
ESP32 (ChordPixelCharacteristicCallbacks)
    ↓
Parse with parseChordCommandWithFingers() - O(n)
    ↓
Convert to pixels with convertChordPositionsToPixelsWithFingers() - O(1)
    ↓
Display on LED strip with finger-specific colors
```

## Example Usage

### Input Data (from chords.json)
```json
"c": {
  "fret_num": [-1, 3, 2, 0, 1, 0],
  "finger_pos": [-1, 3, 2, -1, 1, -1]
}
```

### Bluetooth Transmission
```
"[-1, 3, 2, 0, 1, 0]|[-1, 3, 2, -1, 1, -1]"
```

### LED Display
- String 0 (E low): RED (entire column) - no strum
- String 1 (A): YELLOW at fret 3 - finger 3
- String 2 (D): CYAN at fret 2 - finger 2
- String 3 (G): GREEN (entire column) - open string
- String 4 (B): BLUE at fret 1 - finger 1
- String 5 (E high): GREEN (entire column) - open string

## Performance Characteristics

### Time Complexity
- **Parsing**: O(n) where n = string length (~40-60 characters)
- **LED Mapping**: O(1) - fixed 6 strings, max 7 frets/string = 42 operations
- **Total**: O(n) linear time, highly efficient

### Space Complexity
- **Arrays**: 2 × 6 integers (12 integers total)
- **Strings**: Minimal temporary storage during parsing
- **Total**: O(1) constant space

### Advantages
1. **Minimal overhead**: Single transmission includes all data
2. **Fast parsing**: Single pass through string
3. **Backward compatible**: Falls back gracefully if no finger data present
4. **Extensible**: Easy to add more finger colors or modify scheme

## Testing Notes

### To Verify Implementation:
1. Select any chord in the mobile app
2. Check serial output for parsed fret and finger positions
3. Verify LED colors match finger positions
4. Test edge cases:
   - Open strings show green
   - No-strum strings show red
   - All 4 finger colors appear correctly

### Known Limitations:
- Maximum 4 distinct finger colors (fingers 1-4)
- Assumes standard 6-string guitar layout
- Requires matching fret and finger array lengths

## Future Enhancements
1. Add configurable color schemes via app settings
2. Support for alternative tunings
3. Animation effects for chord transitions
4. Brightness adjustment based on finger pressure
