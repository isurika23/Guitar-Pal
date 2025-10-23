# Hardware Wiring Guide - Finger Recognition System

## Required Components

1. **ESP32 Development Board** (with GPIO pins)
2. **6x Guitar Strings** (connected to fretboard)
3. **6x 10kΩ Resistors** (pull-down resistors for fret inputs)
4. **Connecting Wires**
5. **Breadboard** (optional, for organizing connections)

## Wiring Diagram

### String Connections (OUTPUT Pins)

Connect one end of each guitar string to the following ESP32 GPIO pins:

| String | ESP32 GPIO | Note |
|--------|-----------|------|
| String 0 (High E - thinnest) | GPIO 32 | OUTPUT |
| String 1 (B) | GPIO 33 | OUTPUT |
| String 2 (G) | GPIO 25 | OUTPUT |
| String 3 (D) | GPIO 26 | OUTPUT |
| String 4 (A) | GPIO 27 | OUTPUT |
| String 5 (Low E - thickest) | GPIO 13 | OUTPUT |

**Important**: Only ONE string will be HIGH at any given time during scanning.

### Fret Connections (INPUT Pins with Pull-Down Resistors)

For each fret (1-6), connect as follows:

1. One end of fret wire → ESP32 GPIO Input Pin
2. Same GPIO pin → 10kΩ resistor → GND
3. Other end of fret wire → Metal fret on guitar

| Fret | ESP32 GPIO | Pull-Down Resistor |
|------|-----------|-------------------|
| Fret 1 | GPIO 15 | 10kΩ to GND |
| Fret 2 | GPIO 16 | 10kΩ to GND |
| Fret 3 | GPIO 17 | 10kΩ to GND |
| Fret 4 | GPIO 18 | 10kΩ to GND |
| Fret 5 | GPIO 19 | 10kΩ to GND |
| Fret 6 | GPIO 21 | 10kΩ to GND |

**Note**: Fret 0 (open string) requires no physical connection.

## Breadboard Layout Example

```
ESP32                 Breadboard                Guitar
-----                 ----------                ------

GPIO 32 ────────────────────────────────────> String 0
GPIO 33 ────────────────────────────────────> String 1
GPIO 25 ────────────────────────────────────> String 2
GPIO 26 ────────────────────────────────────> String 3
GPIO 27 ────────────────────────────────────> String 4
GPIO 13 ────────────────────────────────────> String 5

GPIO 15 ───┬─────────────────────────────────> Fret 1
           │
         [10kΩ]
           │
          GND

GPIO 16 ───┬─────────────────────────────────> Fret 2
           │
         [10kΩ]
           │
          GND

GPIO 17 ───┬─────────────────────────────────> Fret 3
           │
         [10kΩ]
           │
          GND

GPIO 18 ───┬─────────────────────────────────> Fret 4
           │
         [10kΩ]
           │
          GND

GPIO 19 ───┬─────────────────────────────────> Fret 5
           │
         [10kΩ]
           │
          GND

GPIO 21 ───┬─────────────────────────────────> Fret 6
           │
         [10kΩ]
           │
          GND
```

## Physical Guitar Connection

### String Connection Points
- Connect wires to the **bridge** end of each string (where strings are anchored)
- Use **alligator clips** or **solder connections** for reliable contact
- Ensure strings are electrically isolated from each other

### Fret Connection Points
- Connect wires to the **metal fret bars** on the fretboard
- Use **alligator clips** on the side of the fretboard
- Ensure frets have good electrical continuity

## How It Works

### Detection Principle

When a finger presses a string against a fret:

1. **String is energized** (set to HIGH, ~3.3V)
2. **Finger creates electrical contact** between string and fret
3. **Current flows** from string → finger → fret → GPIO input pin
4. **ESP32 reads HIGH** on that fret input pin
5. **Position is detected**: (string number, fret number)

### Scanning Sequence

```
Time 0ms:    String 0 HIGH, read all frets → detect fret on string 0
Time 0.1ms:  String 0 LOW
Time 0.15ms: String 1 HIGH, read all frets → detect fret on string 1
Time 0.25ms: String 1 LOW
Time 0.3ms:  String 2 HIGH, read all frets → detect fret on string 2
...
Time 0.9ms:  String 5 HIGH, read all frets → detect fret on string 5
Time 1.0ms:  String 5 LOW, complete scan cycle
```

Full scan cycle: **~1ms** (much faster than human reaction time)

## Safety Considerations

### Voltage Levels
- **ESP32 GPIO output**: 3.3V (safe for human contact)
- **Current through finger**: <1mA (imperceptible)
- **Pull-down resistors**: Prevent floating inputs and reduce noise

### Electrical Isolation
- Strings must be **electrically isolated** from guitar body/ground
- Use **non-conductive string anchors** if needed
- Frets should be naturally isolated (typically mounted on wood)

## Troubleshooting

### Problem: No Detection
- **Check string connections**: Ensure good electrical contact at bridge
- **Check fret connections**: Ensure good contact with metal frets
- **Verify pull-down resistors**: Measure resistance (should be ~10kΩ)
- **Test continuity**: Use multimeter to verify string-to-fret contact when pressed

### Problem: False Positives
- **Check for shorts**: Ensure strings don't touch each other
- **Verify pull-down resistors**: May need lower values (e.g., 4.7kΩ)
- **Check grounding**: Ensure common ground between ESP32 and resistors
- **Increase debounce**: Adjust stabilization delay in code

### Problem: Intermittent Detection
- **Clean contacts**: Oxidation on strings/frets can cause issues
- **Tighten connections**: Loose wires cause intermittent contact
- **Check solder joints**: Re-solder any cold joints
- **Replace corroded wires**: Use fresh connecting wires

## Testing Procedure

### Step 1: Basic Connectivity Test
1. Upload finger detection code to ESP32
2. Open Serial Monitor (115200 baud)
3. Manually touch string 0 to fret 1
4. Verify Serial Monitor shows: "String 0, Fret 1"

### Step 2: All Strings Test
1. Touch each string to fret 1, one at a time
2. Verify all 6 strings are detected correctly

### Step 3: All Frets Test
1. Touch string 0 to each fret (1-6), one at a time
2. Verify all 6 frets are detected correctly

### Step 4: Multiple Positions Test
1. Press multiple strings at different frets (like a chord)
2. Verify all positions are detected simultaneously

### Step 5: Open String Test
1. Don't press any frets
2. Verify detected positions show fret = 0 for all strings

## Advanced Options

### Alternative Wiring
- **Use analog inputs**: For pressure-sensitive detection
- **Add capacitors**: 100nF across pull-down resistors for noise filtering
- **Use I2C expanders**: For projects with limited GPIO pins

### Alternative Detection Methods
- **Capacitive touch**: Use ESP32's touch pins (no finger contact needed)
- **Optical sensors**: IR LED/photodiode pairs for non-contact detection
- **Pressure sensors**: FSRs (force-sensitive resistors) under strings

## Bill of Materials (BOM)

| Item | Quantity | Specs | Approx. Cost |
|------|----------|-------|--------------|
| ESP32 Dev Board | 1 | With GPIO breakout | $5-10 |
| 10kΩ Resistors | 6 | 1/4W, 5% tolerance | $0.50 |
| Jumper Wires | 20+ | Male-to-male, 20cm | $2 |
| Alligator Clips | 12 | Small, insulated | $3 |
| Breadboard | 1 | Half-size or full-size | $3 |
| **Total** | - | - | **~$15** |

## Pin Assignment Summary

**Conflict Check**: These pins are confirmed NOT to conflict with:
- LED data pin (GPIO 14)
- Bluetooth connection pins (GPIO 2, 4)
- Boot/flash pins (GPIO 0, 2)

**Note**: Avoid using GPIO 6-11 (connected to flash memory on most ESP32 boards).

## Next Steps

After completing the hardware wiring:

1. **Upload firmware** with finger detection code
2. **Test basic detection** using Serial Monitor
3. **Pair with mobile app** via Bluetooth
4. **Select a chord** in the app
5. **Place fingers** and watch for red circles on wrong positions!

## Support

For issues or questions:
- Check Serial Monitor for debug messages
- Verify GPIO pin assignments match this guide
- Measure voltages with multimeter if needed
- Review main implementation document: `FINGER_RECOGNITION_IMPLEMENTATION.md`
