# BPM-Synchronized Scale Display - Visual Reference

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Mobile App                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Scale Practice Widget                                     │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │  User Controls:                                       │ │  │
│  │  │  • Select Scale (C Major, G Minor, etc.)            │ │  │
│  │  │  • Direction (Ascending, Descending, Both)          │ │  │
│  │  │  • BPM (40-200)                                     │ │  │
│  │  │  • Start/Stop                                       │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │  Timer.periodic @ BPM interval                       │ │  │
│  │  │  ↓                                                   │ │  │
│  │  │  _playBeatAndUpdate()                                │ │  │
│  │  │  • Play click sound                                  │ │  │
│  │  │  • Update UI highlight                               │ │  │
│  │  │  • Increment position                                │ │  │
│  │  │  • ↓                                                 │ │  │
│  │  │  _sendCurrentNoteToHardware()                        │ │  │
│  │  │  • Format: [string, fret]                           │ │  │
│  │  │  • Send via BLE                                      │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Bluetooth Service                                        │  │
│  │  sendScaleData([string, fret])                           │  │
│  │  • Characteristic: c3c50c29-d4a5-4998-b382-62dcc1845e12  │  │
│  │  • Write to ESP32                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬─────────────────────────────────────┘
                             │ BLE
                             │ (~20ms latency)
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                         ESP32 Hardware                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Bluetooth Callback                                       │  │
│  │  ScalePixelCharacteristicCallbacks::onWrite()            │  │
│  │                                                            │  │
│  │  IF value == "clear":                                     │  │
│  │    → clearGrid()                                          │  │
│  │    → FastLED.show()                                       │  │
│  │                                                            │  │
│  │  ELSE:                                                     │  │
│  │    → parseScaleCommand([string, fret])                   │  │
│  │    → Calculate: gridPos = fret * 6 + string              │  │
│  │    → Map: physicalLED = fretLEDs[gridPos]                │  │
│  │    → leds[physicalLED] = CRGB::Green                     │  │
│  │    → FastLED.show()                                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  LED Strip (WS2812B)                                     │  │
│  │  🟢 Single green LED lit at current note position        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Timing Diagram

```
Time →  0s    1s    2s    3s    4s    5s    6s    7s    8s    9s    10s   11s
        ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────
BPM 60  
Beat:   1     2     3     4     5     6     7     8     1     2     3     4
        │     │     │     │     │     │     │     │     │     │     │     │
Click:  ⚡    ⚡    ⚡    ⚡    ⚡    ⚡    ⚡    ⚡    ⚡    ⚡    ⚡    ⚡
Accent: 🔊    ─     ─     ─     🔊    ─     ─     ─     🔊    ─     ─     ─
        │                                           │
Phase:  ├──────────── Count-in (8 beats) ──────────┤─── Playback ───────→
        │                                           │     │     │     │
App UI: │         No highlight                     │ [0,3][0,5][1,2][1,3]
        │                                           │  🟦   🟦   🟦   🟦
        │                                           │
BLE:    │         No transmission                  │[0,3][0,5][1,2][1,3]
        │                                           │  ↓    ↓    ↓    ↓
ESP32:  │         No LED activity                  │ 🟢   🟢   🟢   🟢
LED:    ⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫⚫🟢   🟢   🟢   🟢
```

## Scale Direction Visualization

### C Major Scale Positions
```
String:  0    1    2    3    4    5
        (E)  (A)  (D)  (G)  (B)  (E)
        
Fret 0   ─    ─    ─    ─    ─    ─
Fret 1   ─    ─    ─    ─    ─    ─
Fret 2   ─    ─    ●    ─    ─    ─  ← [2, 2] (5th position)
Fret 3   ●    ●    ─    ─    ─    ─  ← [0, 3] (1st), [1, 3] (3rd)
Fret 4   ─    ─    ●    ─    ─    ─  ← [2, 4] (6th position)
Fret 5   ●    ●    ●    ─    ─    ─  ← [0, 5] (2nd), [1, 5] (4th), [2, 5] (7th)
Fret 6   ─    ─    ─    ─    ─    ─
```

### Ascending Playback
```
Beat:  1     2     3     4     5     6     7     8     Loop
Note:  C     D     E     F     G     A     B     C     →C
Pos:  [0,3] [0,5] [1,2] [1,3] [1,5] [2,2] [2,4] [2,5]  [0,3]
LED:   🟢    🟢    🟢    🟢    🟢    🟢    🟢    🟢     🟢
```

### Descending Playback
```
Beat:  1     2     3     4     5     6     7     8     Loop
Note:  C     B     A     G     F     E     D     C     →C
Pos:  [2,5] [2,4] [2,2] [1,5] [1,3] [1,2] [0,5] [0,3]  [2,5]
LED:   🟢    🟢    🟢    🟢    🟢    🟢    🟢    🟢     🟢
```

### Both Direction Playback
```
Ascending (8 notes):
Beat:  1     2     3     4     5     6     7     8
Note:  C     D     E     F     G     A     B     C
Pos:  [0,3] [0,5] [1,2] [1,3] [1,5] [2,2] [2,4] [2,5]

Descending (6 notes, skip extremes):
Beat:  9     10    11    12    13    14    Loop
Note:  B     A     G     F     E     D     →C
Pos:  [2,4] [2,2] [1,5] [1,3] [1,2] [0,5]  [0,3]

Total: 14 beats per cycle
```

## Data Format Examples

### Clear Command
```
Mobile sends:    "clear"
ESP32 receives:  "clear"
Action:          clearGrid() + FastLED.show()
Result:          All LEDs off: ⚫⚫⚫⚫⚫⚫⚫
```

### Note Position
```
Mobile sends:    "[0, 3]"
ESP32 receives:  "[0, 3]"
Parse:           string=0, fret=3
Calculate:       gridPos = 3*6 + 0 = 3
Map:             physicalLED = fretLEDs[3]
Action:          leds[physicalLED] = Green
Result:          LED at String 0, Fret 3 lights: 🟢
```

## State Machine

```
┌─────────────┐
│   STOPPED   │  ← Initial state
└──────┬──────┘
       │ User presses Start
       ↓
┌─────────────┐
│  COUNT-IN   │  8 beats, no LEDs
│   (Phase)   │  Clicks play, haptics fire
└──────┬──────┘  Beat counter: 0→8
       │ Count-in complete
       ↓
┌─────────────┐
│  PLAYING    │  Send "clear"
│   (Phase)   │  ↓
└──────┬──────┘  Beat 1: Send [0,3], light LED
       │         Beat 2: Send [0,5], light LED
       │         ...
       │         Beat N: Loop to start
       │
       │ User presses Stop
       ↓
┌─────────────┐
│  STOPPING   │  Send "clear"
│             │  Turn off all LEDs
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   STOPPED   │
└─────────────┘
```

## LED Grid Mapping

```
Physical Fretboard Layout:
┌─────────────────────────────────────┐
│  Fret 6  │⚫│⚫│⚫│⚫│⚫│⚫│           │
│  Fret 5  │⚫│⚫│⚫│⚫│⚫│⚫│           │
│  Fret 4  │⚫│⚫│⚫│⚫│⚫│⚫│           │
│  Fret 3  │⚫│⚫│⚫│⚫│⚫│⚫│           │
│  Fret 2  │⚫│⚫│⚫│⚫│⚫│⚫│           │
│  Fret 1  │⚫│⚫│⚫│⚫│⚫│⚫│           │
│  Fret 0  │⚫│⚫│⚫│⚫│⚫│⚫│ (Nut)    │
│          E A D G B E                │
│        String 0→5                   │
└─────────────────────────────────────┘

Grid Position Calculation:
gridPosition = fret * 6 + string

Example: String 2, Fret 4
gridPosition = 4 * 6 + 2 = 26

Physical LED Mapping:
physicalLED = fretLEDs[gridPosition]
physicalLED = fretLEDs[26]

Note: fretLEDs[] array handles serpentine wiring
```

## Communication Protocol

```
┌────────────┐                           ┌────────────┐
│ Mobile App │                           │   ESP32    │
└─────┬──────┘                           └──────┬─────┘
      │                                         │
      │ Service: c3c50c29-d4a5-4998-b382-62dcc1845e10
      │ Characteristic: ...845e12               │
      │                                         │
      │  Write: "clear"                         │
      │────────────────────────────────────────>│
      │                                         │
      │                                 Parse & Execute
      │                                 clearGrid()
      │                                 FastLED.show()
      │                                         │
      │                                    All LEDs off
      │                                         │
      │  Write: "[0, 3]"                        │
      │────────────────────────────────────────>│
      │                                         │
      │                                 Parse [0,3]
      │                                 gridPos = 3
      │                                 LED = fretLEDs[3]
      │                                 leds[LED] = Green
      │                                 FastLED.show()
      │                                         │
      │                            String 0, Fret 3 🟢
      │                                         │
      │  Write: "[0, 5]"                        │
      │────────────────────────────────────────>│
      │                                         │
      │                                 Parse [0,5]
      │                                 gridPos = 5
      │                                 LED = fretLEDs[5]
      │                                 leds[LED] = Green
      │                                 FastLED.show()
      │                                         │
      │                            String 0, Fret 5 🟢
      │                                         │
```

## BPM Conversion Table

```
┌─────┬──────────┬──────────┬──────────┬───────────┐
│ BPM │ ms/beat  │ beats/s  │ notes/min│ Use Case  │
├─────┼──────────┼──────────┼──────────┼───────────┤
│  40 │ 1500 ms  │  0.67    │    40    │ Very Slow │
│  60 │ 1000 ms  │  1.00    │    60    │ Slow      │
│  80 │  750 ms  │  1.33    │    80    │ Moderate  │
│ 100 │  600 ms  │  1.67    │   100    │ Standard  │
│ 120 │  500 ms  │  2.00    │   120    │ Active    │
│ 140 │  429 ms  │  2.33    │   140    │ Brisk     │
│ 160 │  375 ms  │  2.67    │   160    │ Fast      │
│ 180 │  333 ms  │  3.00    │   180    │ Very Fast │
│ 200 │  300 ms  │  3.33    │   200    │ Extreme   │
└─────┴──────────┴──────────┴──────────┴───────────┘

Formula: interval_ms = 60000 / BPM
```

## Error Handling

```
Mobile App Side:
┌─────────────────────────┐
│ _sendCurrentNoteToHardware()
│                          │
│ IF not connected:        │
│   → Return silently      │ (Don't interrupt playback)
│                          │
│ IF clear command:        │
│   → Send "clear"         │
│   → Log action           │
│                          │
│ IF normal note:          │
│   → Validate index       │
│   → Format [string,fret] │
│   → Send via BLE         │
│   → Log transmission     │
└─────────────────────────┘

ESP32 Side:
┌─────────────────────────┐
│ onWrite() callback       │
│                          │
│ Parse command:           │
│   IF "clear" → clearGrid()
│   IF [x,y]:              │
│     → Validate x (0-5)   │
│     → Validate y (0-6)   │
│     → Calculate gridPos  │
│     → Check < NUM_LEDS   │
│     → Light LED          │
│   ELSE:                  │
│     → Log error          │
│     → Ignore command     │
└─────────────────────────┘
```

## Performance Visualization

```
Latency Breakdown @ 120 BPM (500ms intervals):

Mobile App:
├─ Beat fires (0ms)
├─ Update UI (~5ms)
├─ Format data (~1ms)
└─ BLE write (~2ms)
        ↓
    [~8ms total]
        ↓
BLE Transmission:
├─ Bluetooth stack (~10-20ms)
└─ Wireless transmission
        ↓
    [~15ms typical]
        ↓
ESP32:
├─ Receive & parse (~1ms)
├─ Calculate position (~1ms)
├─ Update LED array (~1ms)
└─ FastLED.show() (~3ms)
        ↓
    [~6ms total]
        ↓
Total Latency: ~29ms

At 120 BPM:
- Beat interval: 500ms
- Latency: 29ms
- Percentage: 5.8%
- Result: ✅ Imperceptible!
```

---

**Visual Reference Complete**
**Perfect for understanding system behavior and data flow**
