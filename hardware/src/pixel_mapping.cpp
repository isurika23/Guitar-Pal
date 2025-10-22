#include <Arduino.h>
#include <FastLED.h>
#include "main.h"

void convertChordPositionsToPixels(int *stringPositions, int *pixels)
{
  int pixelCount = 0;

  for (int string = 0; string < 6; string++)
  {
    int fretPosition = stringPositions[string];

    // Handle open strings and muted strings - light up entire column
    if (fretPosition <= 0)
    {
      if (fretPosition < 0)
      {
        Serial.print("Don't strum string ");
        Serial.print(string);
        Serial.println(" - lighting entire column RED");

        // Light up all 7 frets for this string in red
        for (int fret = 0; fret < 7; fret++)
        {
          int gridPosition = fret * 6 + string;
          leds[fretLEDs[gridPosition]] = CRGB::Red;
        }
      }
      else if (fretPosition == 0)
      {
        Serial.print("Open string ");
        Serial.print(string);
        Serial.println(" - lighting entire column GREEN");

        // Light up all 7 frets for this string in green
        for (int fret = 0; fret < 7; fret++)
        {
          int gridPosition = fret * 6 + string;
          leds[fretLEDs[gridPosition]] = CRGB::Green;
        }
      }
      continue;
    }

    // Convert to grid position for pressed fret
    int gridPosition = (fretPosition) * 6 + string;

    // Make sure we don't exceed the valid LED range
    if (gridPosition < NUM_LEDS)
    {
      pixels[pixelCount] = gridPosition;
      leds[fretLEDs[gridPosition]] = CRGB::Blue; // Use blue for normal strummed strings
      pixelCount++;

      Serial.print("String ");
      Serial.print(string);
      Serial.print(", Fret ");
      Serial.print(fretPosition);
      Serial.print(" -> Grid position ");
      Serial.println(gridPosition);
    }
  }

  return;
}

// Convert chord positions to pixels with finger-based color coding
// O(n) time complexity where n = 6 strings
// Color scheme:
//   - Open strings (fret = 0): GREEN (entire column)
//   - No strum (fret = -1): RED (entire column)
//   - Finger 1: BLUE
//   - Finger 2: CYAN
//   - Finger 3: YELLOW
//   - Finger 4: MAGENTA (or ORANGE)
void convertChordPositionsToPixelsWithFingers(int *fretPositions, int *fingerPositions)
{
  Serial.println("Converting chord positions with finger colors...");

  // Define distinct colors for each finger (avoiding green and red)
  CRGB fingerColors[5] = {
      CRGB::White,      // finger 0 (no finger or open) - shouldn't be used for pressed frets
      CRGB::Blue,       // finger 1
      CRGB::Cyan,       // finger 2
      CRGB::Yellow,     // finger 3
      CRGB(255, 165, 0) // finger 4 - Orange (RGB: 255, 165, 0)
  };

  for (int string = 0; string < 6; string++)
  {
    int fretPosition = fretPositions[string];
    int fingerPosition = fingerPositions[string];

    // Handle open strings (fret = 0) - light up entire column GREEN
    if (fretPosition == 0)
    {
      Serial.print("Open string ");
      Serial.print(string);
      Serial.println(" - lighting entire column GREEN");

      for (int fret = 0; fret < 7; fret++)
      {
        int gridPosition = fret * 6 + string;
        leds[fretLEDs[gridPosition]] = CRGB::Green;
      }
      continue;
    }

    // Handle no-strum strings (fret < 0) - light up entire column RED
    if (fretPosition < 0)
    {
      Serial.print("Don't strum string ");
      Serial.print(string);
      Serial.println(" - lighting entire column RED");

      for (int fret = 0; fret < 7; fret++)
      {
        int gridPosition = fret * 6 + string;
        leds[fretLEDs[gridPosition]] = CRGB::Red;
      }
      continue;
    }

    // Handle pressed frets with finger color coding
    int gridPosition = fretPosition * 6 + string;

    // Make sure we don't exceed the valid LED range
    if (gridPosition < NUM_LEDS)
    {
      // Select color based on finger position
      CRGB color;
      if (fingerPosition >= 1 && fingerPosition <= 4)
      {
        color = fingerColors[fingerPosition];
        Serial.print("String ");
        Serial.print(string);
        Serial.print(", Fret ");
        Serial.print(fretPosition);
        Serial.print(", Finger ");
        Serial.print(fingerPosition);
        Serial.print(" -> Grid position ");
        Serial.print(gridPosition);
        Serial.print(" - Color: ");

        // Print color name for debugging
        if (fingerPosition == 1)
          Serial.println("BLUE");
        else if (fingerPosition == 2)
          Serial.println("CYAN");
        else if (fingerPosition == 3)
          Serial.println("YELLOW");
        else if (fingerPosition == 4)
          Serial.println("ORANGE");
      }
      else
      {
        // Default to white if finger position is invalid or not specified
        color = CRGB::White;
        Serial.print("String ");
        Serial.print(string);
        Serial.print(", Fret ");
        Serial.print(fretPosition);
        Serial.print(" (no finger info) -> Grid position ");
        Serial.print(gridPosition);
        Serial.println(" - Color: WHITE");
      }

      leds[fretLEDs[gridPosition]] = color;
    }
    else
    {
      Serial.print("Grid position ");
      Serial.print(gridPosition);
      Serial.println(" exceeds valid LED range");
    }
  }

  Serial.println("Chord conversion complete");
}

void convertScalePositionsToPixels(int scaleData[][2], int scaleCount)
{
  Serial.println("Converting scale positions to pixels...");
  int pixels[scaleCount] = {0}; // Temporary array to hold pixel indices

  for (int i = 0; i < scaleCount; i++)
  {
    int guitarString = scaleData[i][0];
    int fretPosition = scaleData[i][1];

    Serial.print("Scale position ");
    Serial.print(i);
    Serial.print(": String ");
    Serial.print(guitarString);
    Serial.print(", Fret ");
    Serial.println(fretPosition);

    // Convert string and fret to grid position
    // fretPosition corresponds directly to the fret number
    // guitarString corresponds to the string (0-5)
    if (guitarString >= 0 && guitarString < 6)
    {
      int gridPosition = fretPosition * 6 + guitarString;
      pixels[i] = gridPosition;

      // Make sure we don't exceed the valid LED range
      if (gridPosition < NUM_LEDS)
      {
        // clearGrid();
        leds[fretLEDs[gridPosition]] = CRGB::Purple; // Use purple for scale notes
        FastLED.show();
        delay(500); // Briefly show each LED for debugging

        Serial.print("String ");
        Serial.print(guitarString);
        Serial.print(", Fret ");
        Serial.print(fretPosition);
        Serial.print(" -> Grid position ");
        Serial.println(gridPosition);
      }
      else
      {
        Serial.print("Grid position ");
        Serial.print(gridPosition);
        Serial.println(" exceeds valid LED range");
      }
    }
    else
    {
      Serial.print("Invalid string number: ");
      Serial.println(guitarString);
    }
  }

  Serial.print("Final scale pixel indices:");
  for (int j = 0; j < scaleCount; j++)
  {
    Serial.print(pixels[j]);
    if (j < scaleCount - 1)
      Serial.print(", ");
  }
  Serial.println();
  clearGrid();

  for (int j = 0; j < scaleCount; j++)
  {
    int pixelIndex = pixels[scaleCount - 1 - j]; // Reverse order for display
    if (pixelIndex >= 0 && pixelIndex < NUM_LEDS)
    {
      leds[fretLEDs[pixelIndex]] = CRGB::Purple; // Use purple for scale notes
      FastLED.show();
      delay(500); // Briefly show each LED for debugging
    }
  }
}
