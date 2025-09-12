#ifndef MAIN_H
#define MAIN_H

#include <Arduino.h>
#include <FastLED.h>
#include <vector>

// ================== LED Setup ==================
#define DATA_PIN 4
#define NUM_LEDS 64 // 8x8 grid
#define VALID_LEDS 48

extern CRGB leds[NUM_LEDS];
extern int fretLEDs[VALID_LEDS];
extern int guitarStrings[6];

// ================== Function Declarations ==================
void setGridPixeltoFrets();
void setGridColor(std::vector<int> sequence, CRGB color);
void clearGrid();

std::vector<int> pixelCalculator(const std::vector<int> &chordNotes);

#endif // MAIN_H
