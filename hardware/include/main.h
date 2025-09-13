#ifndef MAIN_H
#define MAIN_H

#include <Arduino.h>
#include <FastLED.h>

// ================== LED Setup ==================
#define DATA_PIN 4
#define NUM_LEDS 64 // 8x8 grid
#define VALID_LEDS 48
#define MAX_PIXELS 6

extern CRGB leds[NUM_LEDS];
extern int fretLEDs[VALID_LEDS];
extern int guitarStrings[6];

// ================== Function Declarations ==================
void setGridPixeltoFrets();
void setGridColor(int* sequence, int count, CRGB color);
void clearGrid();

int pixelCalculator(const int* chordNotes, int noteCount, int* pixels);

#endif // MAIN_H