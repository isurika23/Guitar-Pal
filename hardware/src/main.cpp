#include "scale_and_chord_notes.h"
#include "bluetooth.h"
#include "main.h"

CRGB leds[NUM_LEDS];
int fretLEDs[VALID_LEDS];

int guitarStrings[6] = {4, 9, 2, 7, 11, 4};

// for grid board setup;
void setGridPixeltoFrets()
{
  int fretLEDcount = 0;
  for (int i = 0; i < NUM_LEDS; i++)
  {
    if (i % 8 < 6)
    {
      fretLEDs[fretLEDcount] = i;
      fretLEDcount++;
    }
  }
}

void setGridColor(int* sequence, int count, CRGB color)
{
  for (int i = 0; i < count; i++)
  {
    leds[fretLEDs[sequence[i]]] = color;
  }
  FastLED.show();
}

void clearGrid()
{
  for (int i = 0; i < VALID_LEDS; i++)
  {
    leds[fretLEDs[i]] = CRGB::Black;
  }
  FastLED.show();
}

int pixelCalculator(const int* chordNotes, int noteCount, int* pixels)
{
  Serial.println("Calculating pixels for chord notes...");
  int pixelCount = 0;
  
  for (int i = 0; i < 6; i++)
  {
    int currentStringNote = guitarStrings[i];
    int ledPixelIndex = i;
    
    while (ledPixelIndex < VALID_LEDS)
    {
      // Check if current note is in chord
      bool noteFound = false;
      for (int j = 0; j < noteCount; j++) {
        if (chordNotes[j] == currentStringNote) {
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
  setGridPixeltoFrets(); // Initialize the grid with valid LED positions
  Serial.println("Testing WS2812B 8x8 LED Grid (64 LEDs)");

  // Initialize Bluetooth
  setupBluetooth();
}

void loop()
{
  delay(2000); // Wait before repeating
}