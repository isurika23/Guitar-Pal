#include <Arduino.h>
#include <FastLED.h>
#include "main.h"

void convertChordPositionsToPixels(int* stringPositions, int* pixels) {
  int pixelCount = 0;
  
  for (int string = 0; string < 6; string++) {
    int fretPosition = stringPositions[string];
    
    // Skip if no LED should be lit for this string (position 0)
    if (fretPosition <= 0) {
      if(fretPosition < 0){
        Serial.print("Don't strum string: ");
        Serial.println(string);
        pixels[pixelCount] = string; // Indicate no strum for this string
        leds[fretLEDs[pixels[pixelCount]]] = CRGB::Red; // Use red for muted strings
        pixelCount++;
      } else if (fretPosition == 0) {
        Serial.print("Open string: ");
        Serial.println(string);
        pixels[pixelCount] = string; // Indicate open string for this string
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
    if (gridPosition < VALID_LEDS) {
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
