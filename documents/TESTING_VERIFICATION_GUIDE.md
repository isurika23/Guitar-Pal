# Testing & Verification Guide - Finger Color Coding

## Pre-Test Setup

### Hardware
- [ ] ESP32 connected to computer
- [ ] LED strip powered and connected
- [ ] PlatformIO environment ready
- [ ] Serial monitor available (115200 baud)

### Mobile App
- [ ] Flutter environment configured
- [ ] Device/emulator connected
- [ ] Bluetooth enabled
- [ ] App compiled and installed

## Build Instructions

### 1. Hardware Build
```powershell
cd e:\UoM_Academics\Semester_05\Embedded_Systems_Project\Guitar-Pal\hardware
pio run --target clean
pio run --target upload
```

Expected output:
```
SUCCESS: Uploading .pio\build\esp32dev\firmware.bin
...
Writing at 0x00010000... (100 %)
Wrote 1234567 bytes (789012 compressed) at 0x00010000 in 12.3 seconds
```

### 2. Start Serial Monitor
```powershell
pio device monitor
```

Expected initial output:
```
BLE Advertising Started
Init Service UUID: 4fafc201-1fb5-459e-8fcc-c5c9c331914b
Pixel Service UUID: c3c50c29-d4a5-4998-b382-62dcc1845e10
Waiting for mobile app connection...
```

### 3. Mobile App Build
```powershell
cd e:\UoM_Academics\Semester_05\Embedded_Systems_Project\Guitar-Pal\mobile_app
flutter clean
flutter pub get
flutter run
```

## Test Cases

### Test 1: Basic Connection
**Objective**: Verify Bluetooth connection works

1. [ ] Launch mobile app
2. [ ] Tap "Connect to ESP32" button
3. [ ] Wait for connection

**Expected Serial Output**:
```
Client connected
Init service received: Guitar-Pal
Mobile app connected and initialized
```

**Expected App Behavior**:
- Connection status changes to "Connected"
- Green indicator appears

**Result**: ⬜ Pass / ⬜ Fail

---

### Test 2: C Major Chord (All Colors)
**Objective**: Verify all color types display correctly

1. [ ] Navigate to Chord Practice
2. [ ] Select: Note = C, Type = Major
3. [ ] Observe LED display

**Expected Serial Output**:
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

**Expected LED Display**:
- String 0 (E low): 🔴 RED column
- String 1 (A): 🟡 YELLOW at fret 3
- String 2 (D): 🔷 CYAN at fret 2
- String 3 (G): 🟢 GREEN column
- String 4 (B): 🔵 BLUE at fret 1
- String 5 (E high): 🟢 GREEN column

**Result**: ⬜ Pass / ⬜ Fail

---

### Test 3: E Major Chord
**Objective**: Verify multiple open strings

1. [ ] Select: Note = E, Type = Major
2. [ ] Observe LED display

**Expected LED Display**:
- String 0: 🟢 GREEN (open)
- String 1: 🔷 CYAN at fret 2 (finger 2)
- String 2: 🟡 YELLOW at fret 2 (finger 3)
- String 3: 🔵 BLUE at fret 1 (finger 1)
- String 4: 🟢 GREEN (open)
- String 5: 🟢 GREEN (open)

**Result**: ⬜ Pass / ⬜ Fail

---

### Test 4: F Major Chord (Barre)
**Objective**: Verify finger 4 (orange) and barre

1. [ ] Select: Note = F, Type = Major
2. [ ] Observe LED display

**Expected LED Display**:
- String 0: 🔵 BLUE at fret 1 (finger 1 - barre)
- String 1: 🟡 YELLOW at fret 3 (finger 3)
- String 2: 🟠 ORANGE at fret 3 (finger 4)
- String 3: 🔷 CYAN at fret 2 (finger 2)
- String 4: 🔵 BLUE at fret 1 (finger 1 - barre)
- String 5: 🔵 BLUE at fret 1 (finger 1 - barre)

**Result**: ⬜ Pass / ⬜ Fail

---

### Test 5: D Major Chord
**Objective**: Verify multiple no-strum strings

1. [ ] Select: Note = D, Type = Major
2. [ ] Observe LED display

**Expected LED Display**:
- String 0: 🔴 RED (no strum)
- String 1: 🔴 RED (no strum)
- String 2: 🟢 GREEN (open)
- String 3: 🔵 BLUE at fret 2 (finger 1)
- String 4: 🟡 YELLOW at fret 3 (finger 3)
- String 5: 🔷 CYAN at fret 2 (finger 2)

**Result**: ⬜ Pass / ⬜ Fail

---

### Test 6: Minor Chord
**Objective**: Verify minor chord support

1. [ ] Select: Note = A, Type = Minor
2. [ ] Observe LED display

**Expected**: Proper colors display for Am chord
**Result**: ⬜ Pass / ⬜ Fail

---

### Test 7: Chord Change Speed
**Objective**: Verify fast chord switching

1. [ ] Rapidly switch between C, G, D, A chords
2. [ ] Observe LED updates

**Expected**:
- Smooth transitions (<100ms)
- No LED flickering
- Correct colors each time

**Result**: ⬜ Pass / ⬜ Fail

---

### Test 8: Fallback Handling
**Objective**: Verify backwards compatibility

1. [ ] Modify code to send frets only (remove pipe separator)
2. [ ] Select any chord
3. [ ] Observe behavior

**Expected**:
- Serial shows: "No finger data found, parsing fret only"
- LEDs display with WHITE for pressed frets
- Open/no-strum still show GREEN/RED

**Result**: ⬜ Pass / ⬜ Fail

---

### Test 9: Error Handling
**Objective**: Verify invalid data handling

1. [ ] Send malformed data (if possible via testing tool)
2. [ ] Observe serial output

**Expected**:
- Parsing error logged
- No system crash
- Previous display cleared

**Result**: ⬜ Pass / ⬜ Fail

---

### Test 10: Memory & Performance
**Objective**: Verify system stability

1. [ ] Switch chords 50+ times
2. [ ] Monitor serial output
3. [ ] Check for memory leaks

**Expected**:
- No stack overflow messages
- Consistent parsing times (1-2ms)
- No degradation in performance

**Result**: ⬜ Pass / ⬜ Fail

---

## Debugging Guide

### Issue: No LED lights up
**Possible Causes**:
- LED power supply issue
- Wrong LED pin configuration
- FastLED not initialized

**Debug Steps**:
1. Check `main.h` for LED pin definition
2. Verify power connections
3. Test with simple LED test pattern
4. Check serial for "Chord conversion complete"

### Issue: Wrong colors displayed
**Possible Causes**:
- Finger position data incorrect
- Color mapping logic error
- LED color order setting

**Debug Steps**:
1. Check serial output for parsed finger positions
2. Verify `chords.json` has correct `finger_pos` values
3. Check `fingerColors[]` array in `pixel_mapping.cpp`
4. Verify LED color order (RGB vs GRB)

### Issue: Parsing fails
**Possible Causes**:
- BLE data corruption
- String format mismatch
- Buffer overflow

**Debug Steps**:
1. Check serial for "Parsing chord command with fingers"
2. Verify pipe separator present in data
3. Check for special characters in transmission
4. Increase BLE MTU size if needed

### Issue: Bluetooth won't connect
**Possible Causes**:
- BLE not advertising
- UUID mismatch
- Bluetooth disabled

**Debug Steps**:
1. Check serial for "BLE Advertising Started"
2. Verify UUIDs match in app and hardware
3. Restart both devices
4. Clear Bluetooth cache on mobile

## Performance Benchmarks

Record your measurements:

| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| BLE connection time | <5s | _______ | ⬜ |
| Chord data parse time | <5ms | _______ | ⬜ |
| LED update time | <10ms | _______ | ⬜ |
| Total latency | <50ms | _______ | ⬜ |
| Memory usage | <2KB | _______ | ⬜ |

## Sign-Off

- [ ] All test cases passed
- [ ] Documentation reviewed
- [ ] Code committed to repository
- [ ] Demo video recorded

**Tester Name**: _________________
**Date**: _________________
**Overall Result**: ⬜ Pass / ⬜ Fail

**Notes**:
_____________________________________________
_____________________________________________
_____________________________________________
