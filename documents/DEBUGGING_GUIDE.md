# Debugging Guide - Finger Color Coding

## Mobile App Debugging

### Enable Verbose Logging

The chord_practice_widget.dart now includes comprehensive logging:

```dart
print("Complete chord data: $chordJsonString");
print("Fret positions array: $fretNum");
print("Finger positions array: $fingerNum");
print("Fret string to send: $fretPosString");
print("Finger string to send: $fingerPosString");
print("Combined data: $fretPosString|$fingerPosString");
```

### Expected Output for C Major Chord

When selecting C Major chord, you should see:

```
Complete chord data: {"chord":"C Major","notes":["C","E","G"],"fret_positions":[-1,3,2,0,1,0],"finger_positions":[-1,3,2,-1,1,-1],"no_strum":["E_low"]}
Fret positions array: [-1, 3, 2, 0, 1, 0]
Finger positions array: [-1, 3, 2, -1, 1, -1]
Fret string to send: [-1, 3, 2, 0, 1, 0]
Finger string to send: [-1, 3, 2, -1, 1, -1]
Combined data: [-1, 3, 2, 0, 1, 0]|[-1, 3, 2, -1, 1, -1]
Sent chord data to chord pixel characteristic: [-1, 3, 2, 0, 1, 0]|[-1, 3, 2, -1, 1, -1]
```

### Common Issues

#### Issue 1: Finger positions showing as empty []
**Symptom**: `Finger positions array: []`

**Cause**: 
- Chord JSON doesn't have `finger_pos` field
- Wrong chord type key (should be lowercase: "major", "minor")
- Wrong note key format

**Solution**:
1. Verify chords.json has `finger_pos` for all chords
2. Check chordType is correctly lowercased: `String chordTypeKey = chordType.toLowerCase();`
3. Verify note mapping in `_noteToJsonKey()` function

#### Issue 2: Data not being sent
**Symptom**: No "Sent chord data" message

**Cause**:
- Bluetooth not connected
- Characteristic not found

**Solution**:
1. Check connection status
2. Verify "Found chord pixel characteristic" message appeared during connection
3. Check UUID matches: `c3c50c29-d4a5-4998-b382-62dcc1845e11`

#### Issue 3: Wrong data format
**Symptom**: Data sent but ESP32 shows parsing errors

**Cause**:
- String encoding issue
- Special characters in data

**Solution**:
1. Verify pipe separator `|` is present in combined data
2. Check no extra spaces or characters
3. Ensure brackets are included: `[...]|[...]`

## Hardware (ESP32) Debugging

### Serial Monitor Output

Connect to ESP32 serial monitor at 115200 baud to see parsing details.

### Expected Output for C Major Chord

```
Chord pixel service received: [-1, 3, 2, 0, 1, 0]|[-1, 3, 2, -1, 1, -1]
Parsing chord command with fingers: [-1, 3, 2, 0, 1, 0]|[-1, 3, 2, -1, 1, -1]
 - Fret part: [-1, 3, 2, 0, 1, 0]
 - Finger part: [-1, 3, 2, -1, 1, -1]
Parsed fret positions: -1, 3, 2, 0, 1, 0
Parsed finger positions: -1, 3, 2, -1, 1, -1
Converting chord positions with finger colors...
Don't strum string 0 - lighting entire column RED
String 1, Fret 3, Finger 3 -> Grid position 21 - Color: YELLOW
String 2, Fret 2, Finger 2 -> Grid position 14 - Color: CYAN
Open string 3 - lighting entire column GREEN
String 4, Fret 1, Finger 1 -> Grid position 10 - Color: BLUE
Open string 5 - lighting entire column GREEN
Chord conversion complete
```

### Common Issues

#### Issue 1: No pipe separator found
**Symptom**: `No finger data found, parsing fret only`

**Cause**:
- Mobile app not sending finger data
- BLE transmission corrupted

**Solution**:
1. Check mobile app logs show combined data with `|`
2. Increase BLE MTU if needed
3. Add delay between transmissions

#### Issue 2: Parsing fails
**Symptom**: `Parsed tokens: 0` or `Warning: fret count != finger count`

**Cause**:
- Malformed data
- Buffer overflow
- String termination issue

**Solution**:
1. Check BLE characteristic size (should be at least 60 bytes)
2. Verify String conversion: `String value = String(pCharacteristic->getValue().c_str());`
3. Add null terminator check

#### Issue 3: Wrong colors displayed
**Symptom**: LEDs light up but wrong colors

**Cause**:
- Finger position not in range 1-4
- Color mapping error
- LED color order (RGB vs GRB)

**Solution**:
1. Verify finger positions in serial output
2. Check fingerColors array in pixel_mapping.cpp
3. Test LED strip with known colors
4. Check FastLED configuration for color order

## Data Flow Verification

### Step-by-Step Checklist

1. **Chord Selection**
   - [ ] User selects chord in app
   - [ ] `_sendChordToESP32()` is called
   - [ ] Chord data loaded from JSON

2. **Data Extraction**
   - [ ] `fret_num` extracted: `List<int>.from(chordInfo['fret_num'])`
   - [ ] `finger_pos` extracted: `List<int>.from(chordInfo['finger_pos'])`
   - [ ] Both arrays have 6 elements

3. **String Conversion**
   - [ ] `.toString()` produces format: `[-1, 3, 2, 0, 1, 0]`
   - [ ] Spaces after commas are OK
   - [ ] Brackets included

4. **Data Combination**
   - [ ] Pipe separator added: `$fretPosString|$fingerPosString`
   - [ ] Combined string printed to console
   - [ ] Example: `[-1, 3, 2, 0, 1, 0]|[-1, 3, 2, -1, 1, -1]`

5. **BLE Transmission**
   - [ ] `sendChordData(fretPosString, fingerPosString)` called
   - [ ] Data combined in service method
   - [ ] `.codeUnits` converts to bytes
   - [ ] Write to characteristic succeeds

6. **ESP32 Reception**
   - [ ] Callback triggered: `ChordPixelCharacteristicCallbacks::onWrite()`
   - [ ] Data received as string
   - [ ] Printed to serial monitor

7. **Parsing**
   - [ ] `parseChordCommandWithFingers()` called
   - [ ] Pipe separator found
   - [ ] Both parts parsed successfully
   - [ ] 6 tokens extracted from each part

8. **LED Mapping**
   - [ ] `convertChordPositionsToPixelsWithFingers()` called
   - [ ] Each string processed (0-5)
   - [ ] Open strings → green columns
   - [ ] No-strum → red columns
   - [ ] Finger 1-4 → specific colors

9. **Display**
   - [ ] `FastLED.show()` called
   - [ ] LEDs light up with correct colors
   - [ ] No flickering or delay

## Testing Tools

### Manual BLE Test (Optional)

You can use a BLE testing app to manually send data:

1. Connect to ESP32 BLE device
2. Find chord pixel characteristic: `c3c50c29-d4a5-4998-b382-62dcc1845e11`
3. Write test data: `[-1, 3, 2, 0, 1, 0]|[-1, 3, 2, -1, 1, -1]`
4. Observe LED response

### Serial Command Test

Add to main.cpp for testing without BLE:

```cpp
void testChordParsing() {
  String testData = "[-1, 3, 2, 0, 1, 0]|[-1, 3, 2, -1, 1, -1]";
  int fretTokens[6];
  int fingerTokens[6];
  int count = parseChordCommandWithFingers(testData, fretTokens, fingerTokens, 6);
  
  Serial.print("Test parsing result: ");
  Serial.println(count);
  
  clearGrid();
  convertChordPositionsToPixelsWithFingers(fretTokens, fingerTokens);
  FastLED.show();
}
```

Call in `setup()` after initializing LEDs.

## Performance Monitoring

### Timing Measurements

Add timing to critical sections:

```cpp
unsigned long startTime = millis();
parseChordCommandWithFingers(value, fretTokens, fingerTokens, 6);
unsigned long parseTime = millis() - startTime;
Serial.print("Parse time: ");
Serial.print(parseTime);
Serial.println("ms");
```

Expected times:
- Parsing: <5ms
- LED update: <10ms
- Total: <20ms

### Memory Usage

Check free heap:

```cpp
Serial.print("Free heap: ");
Serial.println(ESP.getFreeHeap());
```

Should remain stable (>100KB) even after many chord changes.

## Troubleshooting Flowchart

```
Data not displayed?
  ├─ Check BLE connection
  │   └─ No connection? → Verify UUIDs match
  │   └─ Connected? → Continue
  │
  ├─ Check mobile app logs
  │   └─ No "Sent chord data"? → BLE characteristic not found
  │   └─ Shows "Sent chord data"? → Continue
  │
  ├─ Check ESP32 serial
  │   └─ No "received"? → BLE transmission failed
  │   └─ Shows "received"? → Continue
  │
  ├─ Check parsing
  │   └─ "No finger data"? → Pipe separator missing
  │   └─ "Parsed 0 tokens"? → Invalid format
  │   └─ Parsed successfully? → Continue
  │
  └─ Check LED display
      └─ No lights? → Power/wiring issue
      └─ Wrong colors? → Check color mapping
      └─ Correct! → Done
```

## Additional Resources

- FastLED documentation: http://fastled.io
- ESP32 BLE guide: https://github.com/nkolban/esp32-snippets
- Flutter Bluetooth Plus: https://pub.dev/packages/flutter_blue_plus
