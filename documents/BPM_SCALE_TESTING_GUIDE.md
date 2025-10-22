# Quick Test Guide - BPM-Synchronized Scale Display

## Pre-Test Checklist

- [ ] ESP32 programmed with updated bluetooth.cpp
- [ ] Mobile app built with updated scale_practice_widget.dart
- [ ] Bluetooth enabled on mobile device
- [ ] LED strip connected and powered
- [ ] Serial monitor ready (115200 baud)

## Test Procedure

### Test 1: Basic Connection & Scale Selection

1. **Start ESP32**
   ```
   Expected Serial Output:
   BLE Advertising Started
   Waiting for mobile app connection...
   ```

2. **Connect from Mobile App**
   ```
   Expected Serial Output:
   Client connected
   Found scale pixel characteristic
   ```

3. **Select C Major Scale**
   ```
   Mobile Console:
   Scale selected: C Major with 8 positions
   Cleared hardware display for new scale selection
   
   ESP32 Serial:
   Scale pixel service received: clear
   Clearing scale display
   ```
   
   ✅ **Pass Criteria**: All LEDs turn off

---

### Test 2: Ascending Scale Playback

1. **Set Direction: Ascending**
2. **Set BPM: 60** (slow for easy verification)
3. **Press Start Metronome**

**Count-in Phase (8 beats):**
```
Expected: 
- Click sounds every 1 second
- "Count-in: 1/8", "Count-in: 2/8", etc.
- No LEDs lit yet
```

**Playback Phase:**
```
Beat 1:
  Mobile: Sent note to hardware: String 0, Fret 3 -> [0, 3]
  ESP32:  Lighting note: String 0, Fret 3
  LED:    Green light on String 0, Fret 3

Beat 2:
  Mobile: Sent note to hardware: String 0, Fret 5 -> [0, 5]
  ESP32:  Lighting note: String 0, Fret 5
  LED:    Green light on String 0, Fret 5
  
... continues through all 8 positions ...

Beat 9: Loops back to position 0
```

✅ **Pass Criteria**:
- Each beat lights ONE LED
- LED matches app highlight
- Progresses low to high (ascending)
- Loops after last note
- Timing is steady at 1 beat/second

---

### Test 3: Descending Scale Playback

1. **Stop current playback**
   ```
   Expected: All LEDs turn off
   ESP32: Clearing scale display
   ```

2. **Set Direction: Descending**
3. **Press Start Metronome**

✅ **Pass Criteria**:
- Notes play high to low (opposite order)
- Still synchronized with app
- Timing consistent

---

### Test 4: Both Direction Playback

1. **Stop and set Direction: Both**
2. **Start Metronome**

✅ **Pass Criteria**:
- First 8 notes: Low to high
- Next 6 notes: High to low (no repeat of extremes)
- Loops back to start
- Total 14 positions in sequence

---

### Test 5: Different BPM Settings

Test each BPM:
- [ ] 40 BPM (1.5 seconds per beat) - Very slow
- [ ] 60 BPM (1 second per beat) - Slow
- [ ] 100 BPM (600ms per beat) - Medium
- [ ] 120 BPM (500ms per beat) - Standard
- [ ] 180 BPM (333ms per beat) - Fast

✅ **Pass Criteria**:
- Each BPM maintains steady timing
- No lag or delay
- LED updates match tempo
- App and hardware stay synchronized

---

### Test 6: Different Scales

Test these scales:
- [ ] C Major (8 notes)
- [ ] G Major (8 notes)
- [ ] A Minor (8 notes)
- [ ] E Minor (8 notes)

✅ **Pass Criteria**:
- Each scale clears previous display
- Correct positions light up
- No incorrect LEDs
- Smooth transitions

---

### Test 7: Stop/Start Cycling

1. **Start playback**
2. **Wait 5 seconds**
3. **Stop**
4. **Verify LEDs off**
5. **Start again**
6. **Repeat 3 times**

✅ **Pass Criteria**:
- LEDs always clear on stop
- Restarts from beginning each time
- Count-in plays every time
- No stuck LEDs

---

### Test 8: Bluetooth Disconnection

1. **Start playback**
2. **Turn off Bluetooth on phone**
3. **Wait 5 seconds**
4. **Turn Bluetooth back on**
5. **Reconnect**
6. **Try playback again**

✅ **Pass Criteria**:
- ESP32 restarts advertising after disconnect
- Can reconnect successfully
- Playback works after reconnection
- No errors or crashes

---

## Common Issues & Solutions

### Issue: No LEDs light up

**Debugging Steps:**
1. Check ESP32 serial - receiving data?
   ```
   Scale pixel service received: [0, 3]
   ```
2. Check mobile console - sending data?
   ```
   Sent note to hardware: String 0, Fret 3
   ```
3. If receiving but not lighting:
   - Check LED power supply
   - Check fretLEDs mapping
   - Test with simple LED pattern

**Solution:**
```cpp
// Add to bluetooth.cpp for debugging
Serial.print("Physical LED index: ");
Serial.println(fretLEDs[gridPosition]);
leds[fretLEDs[gridPosition]] = CRGB::Green;
FastLED.show();
```

---

### Issue: Timing is inconsistent

**Check:**
- BLE signal strength
- Background apps causing lag
- ESP32 processing time

**Solution:**
- Move devices closer
- Close other apps
- Lower BPM for testing

---

### Issue: Wrong notes lighting

**Check mobile console:**
```
Sent note to hardware: String X, Fret Y
```

**Check ESP32 serial:**
```
Lighting note: String X, Fret Y
LED Grid position: Z
```

**Verify:**
- String number correct? (0-5)
- Fret number correct? (0-6)
- Grid calculation: `fret * 6 + string`
- Physical LED mapping in fretLEDs array

---

### Issue: LED stays on after stop

**Check ESP32 received clear:**
```
Scale pixel service received: clear
Clearing scale display
```

**If not received:**
- Check Bluetooth connection
- Try sending "clear" manually

**If received but LED stuck:**
- Power cycle ESP32
- Check clearGrid() function

---

## Performance Benchmarks

Record your measurements:

| Test | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| BLE latency | <30ms | ____ms | ⬜ |
| LED update | <5ms | ____ms | ⬜ |
| 60 BPM accuracy | 1000ms ±10ms | ____ms | ⬜ |
| 120 BPM accuracy | 500ms ±5ms | ____ms | ⬜ |
| Count-in duration | 8 seconds | ____s | ⬜ |

---

## Expected Console Output Examples

### Mobile App (Ascending C Major at 60 BPM):
```
Scale selected: C Major with 8 positions
Cleared hardware display for new scale selection
Playing ACCENT click
Playing regular click
Playing regular click
Playing regular click
Playing ACCENT click
... (count-in 8 beats) ...
Sent clear command to hardware
Sent note to hardware: String 0, Fret 3 -> [0, 3]
Sent note to hardware: String 0, Fret 5 -> [0, 5]
Sent note to hardware: String 1, Fret 2 -> [1, 2]
Sent note to hardware: String 1, Fret 3 -> [1, 3]
Sent note to hardware: String 1, Fret 5 -> [1, 5]
Sent note to hardware: String 2, Fret 2 -> [2, 2]
Sent note to hardware: String 2, Fret 4 -> [2, 4]
Sent note to hardware: String 2, Fret 5 -> [2, 5]
Sent note to hardware: String 0, Fret 3 -> [0, 3]  (loop)
...
```

### ESP32 Serial:
```
Scale pixel service received: clear
Clearing scale display
Scale pixel service received: clear
Clearing scale display
Scale pixel service received: [0, 3]
Lighting note: String 0, Fret 3
LED Grid position 3 -> Physical LED 15
Scale pixel service received: [0, 5]
Lighting note: String 0, Fret 5
LED Grid position 5 -> Physical LED 12
Scale pixel service received: [1, 2]
Lighting note: String 1, Fret 2
LED Grid position 13 -> Physical LED 28
...
```

---

## Sign-Off

**Tester**: _______________
**Date**: _______________
**Result**: ⬜ Pass / ⬜ Fail

**Issues Found**:
_________________________________
_________________________________
_________________________________

**Notes**:
_________________________________
_________________________________
_________________________________
