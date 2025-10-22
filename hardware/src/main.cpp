#include "scale_and_chord_notes.h"
#include "bluetooth.h"
#include "main.h"

CRGB leds[NUM_LEDS];
int fretLEDs[NUM_LEDS];

int guitarStrings[6] = {4, 9, 2, 7, 11, 4};

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

  delay(2000); // Wait before repeating
}