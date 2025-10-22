#ifndef MAIN_H
#define MAIN_H

#include <Arduino.h>
#include <FastLED.h>

// ================== LED Setup ==================
#define DATA_PIN 14
#define NUM_LEDS 42 // 7x6 LED strip (7 frets x 6 strings)
#define MAX_PIXELS 6
#define BL_CONNECTED_PIN 2    // GPIO pin for Bluetooth connection status
#define BL_DISCONNECTED_PIN 4 // GPIO pin for Bluetooth disconnection status

extern CRGB leds[NUM_LEDS];
extern int fretLEDs[NUM_LEDS];
extern int guitarStrings[6];

// ================== Function Declarations ==================
void setLEDsToFrets();
void setGridColor(int *sequence, int count, CRGB color);
void clearGrid();

int pixelCalculator(const int *chordNotes, int noteCount, int *pixels);

#endif // MAIN_H