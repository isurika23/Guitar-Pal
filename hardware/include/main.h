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

// ================== Finger Detection GPIO Pins ==================
// String output pins (energize one at a time) - HIGH output to detect fret presses
#define STRING_0_PIN 5  // String 0 (thinnest) - HIGH output pin
#define STRING_1_PIN 18  // String 1 - HIGH output pin
#define STRING_2_PIN 19  // String 2 - HIGH output pin
#define STRING_3_PIN 21  // String 3 - HIGH output pin
#define STRING_4_PIN 22  // String 4 - HIGH output pin
#define STRING_5_PIN 23  // String 5 (thickest) - HIGH output pin

// Fret input pins (read with 10k pull-down resistors) - detect HIGH when string is pressed
// Fret 0 = open string (no physical pin needed)
// Frets 1-6 are the physical frets
#define FRET_1_PIN 27  // Fret 1 input (with 10k pull-down resistor)
#define FRET_2_PIN 26  // Fret 2 input (with 10k pull-down resistor)
#define FRET_3_PIN 25  // Fret 3 input (with 10k pull-down resistor)
#define FRET_4_PIN 33  // Fret 4 input (with 10k pull-down resistor)
#define FRET_5_PIN 32  // Fret 5 input (with 10k pull-down resistor)
#define FRET_6_PIN 35  // Fret 6 input (with 10k pull-down resistor)

// ================== Finger Detection Data Structures ==================
extern int stringPins[6];        // Array of string output pins
extern int fretPins[6];          // Array of fret input pins (frets 1-6)
extern int expectedFretPos[6];   // Expected fret positions for current chord
extern int expectedFingerPos[6]; // Expected finger positions for current chord
extern int detectedFretPos[6];   // Detected fret positions from scanning
extern bool wrongPositions[6];   // Flag array for wrong positions per string

extern CRGB leds[NUM_LEDS];
extern int fretLEDs[NUM_LEDS];
extern int guitarStrings[6];

// ================== Function Declarations ==================
void setLEDsToFrets();
void setGridColor(int *sequence, int count, CRGB color);
void clearGrid();

int pixelCalculator(const int *chordNotes, int noteCount, int *pixels);

// Finger detection functions
void setupFingerDetection();
void scanFingerPositions();
bool checkFingerPositions();
String getWrongPositionsData();

#endif // MAIN_H