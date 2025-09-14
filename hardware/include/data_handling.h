#ifndef DATA_HANDLING_H
#define DATA_HANDLING_H

#include <Arduino.h>

// Function to parse comma-separated string into integer tokens (for chords)
int parseChordCommand(String value, int *tokens, int maxTokens);

// Function to parse nested array string into scale data pairs
int parseScaleCommand(String value, int scaleData[][2], int maxPairs);

#endif // DATA_HANDLING_H
