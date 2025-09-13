#ifndef SCALE_AND_CHORD_NOTES_H
#define SCALE_AND_CHORD_NOTES_H

#include <Arduino.h>

// Constants
#define MAX_SCALE_NOTES 8
#define MAX_CHORD_NOTES 4
#define MAX_SCALE_TYPES 4

// Note names array
extern const char* noteNames[12];

// Scale structures
struct ScalePattern {
  const char* name;
  int intervals[MAX_SCALE_NOTES];
  int length;
};

extern ScalePattern scales[MAX_SCALE_TYPES];

// Function declarations
int generateScale(int root, const char* scaleName, int* output);
int generateChord(int root, const char* chordType, int* output);

#endif