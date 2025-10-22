# Quick Reference - Expected Behavior

## Mobile App Console Output

### When selecting C Major chord:

```
Complete chord data: {"chord":"C Major","notes":["C","E","G"],"fret_positions":[-1,3,2,0,1,0],"finger_positions":[-1,3,2,-1,1,-1],"no_strum":["E_low"]}
Fret positions array: [-1, 3, 2, 0, 1, 0]
Finger positions array: [-1, 3, 2, -1, 1, -1]
Fret string to send: [-1, 3, 2, 0, 1, 0]
Finger string to send: [-1, 3, 2, -1, 1, -1]
Combined data: [-1, 3, 2, 0, 1, 0]|[-1, 3, 2, -1, 1, -1]
Sent chord data to chord pixel characteristic: [-1, 3, 2, 0, 1, 0]|[-1, 3, 2, -1, 1, -1]
```

✅ **Key Points:**
- Finger positions array should NOT be empty
- Combined data must have pipe separator `|`
- Both arrays must have exactly 6 elements

## ESP32 Serial Output

### When receiving C Major chord data:

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

✅ **Key Points:**
- Must show "Parsing chord command with fingers"
- Both fret and finger parts must be separated
- Each string should show its color assignment
- "Chord conversion complete" indicates success

## LED Display

### C Major Visual:

```
String 0 (E low):  🔴🔴🔴🔴🔴🔴🔴  (RED column - don't strum)
String 1 (A):      ⚫⚫⚫🟡⚫⚫⚫  (YELLOW at fret 3 - finger 3)
String 2 (D):      ⚫⚫🔷⚫⚫⚫⚫  (CYAN at fret 2 - finger 2)
String 3 (G):      🟢🟢🟢🟢🟢🟢🟢  (GREEN column - open)
String 4 (B):      ⚫🔵⚫⚫⚫⚫⚫  (BLUE at fret 1 - finger 1)
String 5 (E high): 🟢🟢🟢🟢🟢🟢🟢  (GREEN column - open)
                   0 1 2 3 4 5 6  (Frets)
```

## Common Test Chords

### E Major
```
Frets:   [0, 2, 2, 1, 0, 0]
Fingers: [-1, 2, 3, 1, -1, -1]

Expected:
String 0: 🟢 GREEN column (open)
String 1: 🔷 CYAN at fret 2
String 2: 🟡 YELLOW at fret 2
String 3: 🔵 BLUE at fret 1
String 4: 🟢 GREEN column (open)
String 5: 🟢 GREEN column (open)
```

### A Major
```
Frets:   [-1, 0, 2, 2, 2, 0]
Fingers: [-1, -1, 1, 2, 3, -1]

Expected:
String 0: 🔴 RED column (no strum)
String 1: 🟢 GREEN column (open)
String 2: 🔵 BLUE at fret 2
String 3: 🔷 CYAN at fret 2
String 4: 🟡 YELLOW at fret 2
String 5: 🟢 GREEN column (open)
```

### D Major
```
Frets:   [-1, -1, 0, 2, 3, 2]
Fingers: [-1, -1, -1, 1, 3, 2]

Expected:
String 0: 🔴 RED column (no strum)
String 1: 🔴 RED column (no strum)
String 2: 🟢 GREEN column (open)
String 3: 🔵 BLUE at fret 2
String 4: 🟡 YELLOW at fret 3
String 5: 🔷 CYAN at fret 2
```

### F Major (Barre)
```
Frets:   [1, 3, 3, 2, 1, 1]
Fingers: [1, 3, 4, 2, 1, 1]

Expected:
String 0: 🔵 BLUE at fret 1 (barre)
String 1: 🟡 YELLOW at fret 3
String 2: 🟠 ORANGE at fret 3
String 3: 🔷 CYAN at fret 2
String 4: 🔵 BLUE at fret 1 (barre)
String 5: 🔵 BLUE at fret 1 (barre)
```

## Verification Steps

1. **Launch mobile app** → See chord selection screen
2. **Connect Bluetooth** → Status shows "Connected"
3. **Select C Major** → Console shows all 6 debug lines
4. **Check finger array** → Should be `[-1, 3, 2, -1, 1, -1]`
5. **Check combined data** → Should have `|` separator
6. **Check ESP32 serial** → Shows parsing details
7. **Check LEDs** → Match expected colors above

## Red Flags 🚩

❌ Finger positions array is empty: `[]`
❌ No pipe separator in combined data
❌ ESP32 shows: "No finger data found"
❌ All LEDs same color
❌ No serial output on ESP32
❌ Parsing shows 0 tokens

## Success Indicators ✅

✅ Finger positions has 6 elements
✅ Combined data format: `[...]|[...]`
✅ ESP32 shows: "Parsing chord command with fingers"
✅ Each string shows correct color name
✅ LEDs display multiple colors
✅ Colors match finger numbers
