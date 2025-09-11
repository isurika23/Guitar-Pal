#include "scale_and_chord_notes.h"
#include "bluetooth.h"
#include "main.h"

CRGB leds[NUM_LEDS];
int fretLEDs[VALID_LEDS];

int guitarStrings[6] = {4, 9, 2, 7, 11, 4};

// // Scale interval patterns
// const int T = 2;
// const int S = 1;

// // Map of scale name -> vector of intervals
// std::map<std::string, std::vector<int>> scales = {
//     {"Major", {T, T, S, T, T, T, S}},
//     {"Minor", {T, S, T, T, S, T, T}},
//     // {"Harmonic Minor", {T, S, T, T, S, 3, S}},    // example
//     // {"Pentatonic Major", {T, T, T + S, T, T + S}} // example
// };

// static const char *noteNames[12] = {
//   "C", "C#", "D", "D#", "E", "F",
//   "F#", "G", "G#", "A", "A#", "B"
// };

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
      // } else {
    }
  }
}

void setGridColor(std::vector<int> sequence, CRGB color)
{
  for (int i : sequence)
  {
    leds[fretLEDs[i]] = color;
    // FastLED.show();
    // delay(500);
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

std::vector<int> pixelCalculator(const std::vector<int> &chordNotes)
{
  Serial.println("Calculating pixels for chord notes...");
  std::vector<int> pixels;
  for (int i = 0; i < 6; i++)
  {
    int currentStringNote = guitarStrings[i];
    int ledPixelIndex = i;
    while (true)
    {
      if (std::find(chordNotes.begin(), chordNotes.end(), currentStringNote) != chordNotes.end())
      {
      Serial.print("String: ");
      Serial.println(i);
      Serial.print(" Fret: ");
      Serial.println(ledPixelIndex);
        pixels.push_back(ledPixelIndex);
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
  // std::cout << "Pixels to light: ";
  // for (int pixel : pixels)
  // {
  //   std::cout << pixel << " ";
  // }
  // std::cout << std::endl;
  return pixels;
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
  // Example usage
  // clearGrid();
  // int root = 0; // C
  // std::string chordName = "Major";
  // std::vector<int> chordNotes = generateChord(root, chordName);
  // Serial.print("Chord Notes: ");
  // for (int note : chordNotes)
  // {
  //   Serial.print(noteNames[note]);
  //   Serial.print(" ");
  // }
  // Serial.println();

  // std::vector<int> lightPixel = pixelCalculator(chordNotes);
  // // Set grid color to blue for the major scale
  // Serial.print("Lighting up pixels for chord: ");
  // Serial.println(chordName.c_str());
  // setGridColor(lightPixel, CRGB::Blue);
  // delay(1000);

  // // Clear the grid after displaying the scale
  // clearGrid();

  delay(2000); // Wait before repeating
}