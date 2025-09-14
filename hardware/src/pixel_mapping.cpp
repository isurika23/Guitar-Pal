#include <Arduino.h>
#include <FastLED.h>
#include "main.h"

void convertChordPositionsToPixels(int *stringPositions, int *pixels)
{
  int pixelCount = 0;

  for (int string = 0; string < 6; string++)
  {
    int fretPosition = stringPositions[string];

    // Skip if no LED should be lit for this string (position 0)
    if (fretPosition <= 0)
    {
      if (fretPosition < 0)
      {
        Serial.print("Don't strum string: ");
        Serial.println(string);
        pixels[pixelCount] = string;                    // Indicate no strum for this string
        leds[fretLEDs[pixels[pixelCount]]] = CRGB::Red; // Use red for muted strings
        pixelCount++;
      }
      else if (fretPosition == 0)
      {
        Serial.print("Open string: ");
        Serial.println(string);
        pixels[pixelCount] = string;                      // Indicate open string for this string
        leds[fretLEDs[pixels[pixelCount]]] = CRGB::Green; // Use green for open strings
        pixelCount++;
      }
      continue;
    }

    // Convert to grid position
    // fretPosition 1 = fret 0 (open string) = LED indices 0-5
    // fretPosition 2 = fret 1 = LED indices 6-11, etc.
    int gridPosition = (fretPosition) * 6 + string;

    // Make sure we don't exceed the valid LED range
    if (gridPosition < VALID_LEDS)
    {
      pixels[pixelCount] = gridPosition;
      leds[fretLEDs[gridPosition]] = CRGB::Blue; // Use blue for normal strummed strings
      pixelCount++;

      Serial.print("String ");
      Serial.print(string);
      Serial.print(", Position ");
      Serial.print(fretPosition);
      Serial.print(" -> Grid position ");
      Serial.println(gridPosition);
    }
  }

  return;
}

void convertScalePositionsToPixels(int scaleData[][2], int scaleCount)
{
  Serial.println("Converting scale positions to pixels...");

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

      // Make sure we don't exceed the valid LED range
      if (gridPosition < VALID_LEDS)
      {
        // clearGrid();
        leds[fretLEDs[gridPosition]] = CRGB::Purple; // Use purple for scale notes
        FastLED.show();
        delay(200); // Briefly show each LED for debugging

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
}
