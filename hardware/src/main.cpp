#include "scale_and_chord_notes.h"
#include "bluetooth.h"
#include "main.h"

CRGB leds[NUM_LEDS];
int fretLEDs[NUM_LEDS];

int guitarStrings[6] = {4, 9, 2, 7, 11, 4};

// ================== Finger Detection Arrays ==================
// GPIO pin arrays for string outputs and fret inputs
int stringPins[6] = {STRING_0_PIN, STRING_1_PIN, STRING_2_PIN, STRING_3_PIN, STRING_4_PIN, STRING_5_PIN};
int fretPins[6] = {FRET_1_PIN, FRET_2_PIN, FRET_3_PIN, FRET_4_PIN, FRET_5_PIN, FRET_6_PIN};

// Expected and detected finger positions
int expectedFretPos[6] = {-1, -1, -1, -1, -1, -1};   // Expected fret positions for current chord
int expectedFingerPos[6] = {-1, -1, -1, -1, -1, -1}; // Expected finger positions for current chord
int detectedFretPos[6] = {-1, -1, -1, -1, -1, -1};   // Detected fret positions from scanning
bool wrongPositions[6] = {false, false, false, false, false, false}; // Wrong position flags

// Initialize fretLEDs array with serpentine mapping
// Even rows (frets 0, 2, 4, 6): left-to-right
// Odd rows (frets 1, 3, 5): right-to-left
void setLEDsToFrets()
{
  int gridIndex = 0; // Index in the fretLEDs array (logical position)

  for (int fret = 0; fret < 7; fret++)
  {
    if (fret % 2 == 0)
    {
      // Even rows: left-to-right (strings 0-5)
      for (int string = 0; string < 6; string++)
      {
        int ledIndex = fret * 6 + string;
        fretLEDs[gridIndex] = ledIndex;
        gridIndex++;
      }
    }
    else
    {
      // Odd rows: right-to-left (strings 5-0)
      for (int string = 5; string >= 0; string--)
      {
        int ledIndex = fret * 6 + string;
        fretLEDs[gridIndex] = ledIndex;
        gridIndex++;
      }
    }
  }

  // Print the mapping for debugging
  Serial.println("Fret to LED mapping initialized:");
  Serial.println("Grid Index -> LED Index (Fret, String)");
  for (int i = 0; i < NUM_LEDS; i++)
  {
    int fret = i / 6;
    int string = i % 6;
    Serial.print("Grid[");
    Serial.print(i);
    Serial.print("] -> LED[");
    Serial.print(fretLEDs[i]);
    Serial.print("] (Fret ");
    Serial.print(fret);
    Serial.print(", String ");
    Serial.print(string);
    Serial.println(")");
  }
}

// void setGridColor(int* sequence, int count, CRGB color)
// {
//   for (int i = 0; i < count; i++)
//   {
//     leds[fretLEDs[sequence[i]]] = color;
//   }
//   FastLED.show();
// }

void clearGrid()
{
  for (int i = 0; i < NUM_LEDS; i++)
  {
    leds[fretLEDs[i]] = CRGB::Black;
  }
  FastLED.show();
}

int pixelCalculator(const int *chordNotes, int noteCount, int *pixels)
{
  Serial.println("Calculating pixels for chord notes...");
  int pixelCount = 0;

  for (int i = 0; i < 6; i++)
  {
    int currentStringNote = guitarStrings[i];
    int ledPixelIndex = i;

    while (ledPixelIndex < NUM_LEDS)
    {
      // Check if current note is in chord
      bool noteFound = false;
      for (int j = 0; j < noteCount; j++)
      {
        if (chordNotes[j] == currentStringNote)
        {
          noteFound = true;
          break;
        }
      }

      if (noteFound)
      {
        Serial.print("String: ");
        Serial.println(i);
        Serial.print(" Fret: ");
        Serial.println(ledPixelIndex);
        pixels[pixelCount++] = ledPixelIndex;
        break;
      }

      Serial.print("String: ");
      Serial.println(i);
      Serial.print(" Fret: ");
      Serial.println(ledPixelIndex);
      currentStringNote = (currentStringNote + 1) % 12; // Move to the next fret
      ledPixelIndex += 6;
    }
  }

  return pixelCount;
}

// ================== Finger Detection Functions ==================

/// Initialize GPIO pins for finger detection
/// String pins as OUTPUT (to energize one at a time)
/// Fret pins as INPUT (with external 10k pull-down resistors)
void setupFingerDetection()
{
  Serial.println("Initializing finger detection GPIO pins...");
  
  // Configure string pins as outputs (initially LOW)
  for (int i = 0; i < 6; i++)
  {
    pinMode(stringPins[i], OUTPUT);
    digitalWrite(stringPins[i], LOW);
    Serial.print("String ");
    Serial.print(i);
    Serial.print(" (GPIO ");
    Serial.print(stringPins[i]);
    Serial.println(") configured as OUTPUT");
  }
  
  // Configure fret pins as inputs (external 10k pull-down resistors)
  for (int i = 0; i < 6; i++)
  {
    pinMode(fretPins[i], INPUT);
    Serial.print("Fret ");
    Serial.print(i + 1);
    Serial.print(" (GPIO ");
    Serial.print(fretPins[i]);
    Serial.println(") configured as INPUT (with 10k pull-down)");
  }
  
  Serial.println("Finger detection GPIO initialization complete");
}

/// Scan all string/fret combinations to detect pressed positions
/// Energizes one string at a time and reads all fret inputs
/// Stores detected positions in detectedFretPos array
void scanFingerPositions()
{
  // Reset detected positions
  for (int i = 0; i < 6; i++)
  {
    detectedFretPos[i] = 0; // 0 = open string (no press detected)
  }
  
  // Scan each string
  for (int stringNum = 0; stringNum < 6; stringNum++)
  {
    // Energize current string
    digitalWrite(stringPins[stringNum], HIGH);
    delayMicroseconds(100); // Small delay for signal stabilization
    
    // Check each fret for this string
    for (int fretNum = 0; fretNum < 6; fretNum++)
    {
      if (digitalRead(fretPins[fretNum]) == HIGH)
      {
        // Fret press detected (fret numbering is 1-6, fretNum is 0-5)
        detectedFretPos[stringNum] = fretNum + 1;
        break; // Only the highest pressed fret matters for a string
      }
    }
    
    // De-energize current string
    digitalWrite(stringPins[stringNum], LOW);
    delayMicroseconds(50); // Small delay before next string
  }
}

/// Check detected positions against expected chord positions
/// Returns true if wrong positions detected, false if all correct
/// Updates wrongPositions array with flags for each string
bool checkFingerPositions()
{
  bool hasWrongPositions = false;
  
  for (int stringNum = 0; stringNum < 6; stringNum++)
  {
    int expected = expectedFretPos[stringNum];
    int detected = detectedFretPos[stringNum];
    
    wrongPositions[stringNum] = false; // Reset flag
    
    // Handle different cases
    if (expected == -1)
    {
      // No strum expected (muted string)
      if (detected > 0)
      {
        // Wrong: finger pressing when string should be muted
        wrongPositions[stringNum] = true;
        hasWrongPositions = true;
        Serial.print("Wrong position on string ");
        Serial.print(stringNum);
        Serial.print(": Expected muted, detected fret ");
        Serial.println(detected);
      }
    }
    else if (expected == 0)
    {
      // Open string expected
      if (detected > 0)
      {
        // Wrong: finger pressing when string should be open
        wrongPositions[stringNum] = true;
        hasWrongPositions = true;
        Serial.print("Wrong position on string ");
        Serial.print(stringNum);
        Serial.print(": Expected open, detected fret ");
        Serial.println(detected);
      }
    }
    else if (expected > 0)
    {
      // Specific fret expected
      if (detected != expected)
      {
        // Wrong: finger on wrong fret or not pressing at all
        wrongPositions[stringNum] = true;
        hasWrongPositions = true;
        Serial.print("Wrong position on string ");
        Serial.print(stringNum);
        Serial.print(": Expected fret ");
        Serial.print(expected);
        Serial.print(", detected fret ");
        Serial.println(detected);
      }
    }
  }
  
  return hasWrongPositions;
}

/// Generate wrong position data string for BLE transmission
/// Format: [[string1, fret1], [string2, fret2], ...]
/// Only includes strings with wrong positions
String getWrongPositionsData()
{
  String data = "[";
  bool first = true;
  
  for (int stringNum = 0; stringNum < 6; stringNum++)
  {
    if (wrongPositions[stringNum])
    {
      if (!first)
      {
        data += ", ";
      }
      data += "[";
      data += String(stringNum);
      data += ", ";
      data += String(detectedFretPos[stringNum]);
      data += "]";
      first = false;
    }
  }
  
  data += "]";
  
  // Return empty array if no wrong positions
  return data;
}

void setup()
{
  FastLED.addLeds<WS2812B, DATA_PIN, GRB>(leds, NUM_LEDS);
  FastLED.setBrightness(20); // Low brightness (~1.28 A)
  Serial.begin(115200);
  Serial.println("Testing WS2812B 7x6 LED Strip (42 LEDs) - Serpentine Pattern");
  setLEDsToFrets(); // Initialize the serpentine mapping
  pinMode(BL_CONNECTED_PIN, OUTPUT);
  pinMode(BL_DISCONNECTED_PIN, OUTPUT);
  digitalWrite(BL_CONNECTED_PIN, LOW);
  digitalWrite(BL_DISCONNECTED_PIN, HIGH);

  // Initialize finger detection GPIO pins
  setupFingerDetection();

  // Initialize Bluetooth
  setupBluetooth();
  clearGrid();
}

void loop()
{
  // Check if we need to restart advertising (additional safety check)
  if (pServer != nullptr && !pServer->getConnectedCount())
  {
    // If no clients connected, restart advertising
    clearGrid();
    digitalWrite(BL_CONNECTED_PIN, LOW);
    digitalWrite(BL_DISCONNECTED_PIN, HIGH);
    Serial.println("No connection detected - Restarting advertising");
    BLEDevice::startAdvertising();
  }

  // Continuously scan for finger positions and check against expected chord
  scanFingerPositions();
  
  // Check if there are wrong positions and send notification
  if (checkFingerPositions())
  {
    // Wrong positions detected - send data to mobile app
    String wrongPosData = getWrongPositionsData();
    sendWrongPositions(wrongPosData);
  }
  else
  {
    // All positions correct - send empty array to clear any previous errors
    sendWrongPositions("[]");
  }

  delay(200); // Scan every 200ms for responsive feedback
}