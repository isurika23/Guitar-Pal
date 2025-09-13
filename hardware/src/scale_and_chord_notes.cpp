#include "scale_and_chord_notes.h"

// Intervals
const int T = 2;
const int S = 1;

// Scale definitions using structs
ScalePattern scales[MAX_SCALE_TYPES] = {
    {"Major", {T, T, S, T, T, T, S}, 7},
    {"Minor", {T, S, T, T, S, T, T}, 7},
    {"Diminished Whole-Half", {T, S, T, S, T, S, T, S}, 8},
    {"Diminished Half-Whole", {S, T, S, T, S, T, S, T}, 8}
};

const char* noteNames[12] = {
  "C", "C#", "D", "D#", "E", "F",
  "F#", "G", "G#", "A", "A#", "B"
};

// Helper function to find scale by name
int findScaleIndex(const char* scaleName) {
    for (int i = 0; i < MAX_SCALE_TYPES; i++) {
        if (strcmp(scales[i].name, scaleName) == 0) {
            return i;
        }
    }
    return -1; // Not found
}

// Generate a scale
int generateScale(int root, const char* scaleName, int* output) {
    int scaleIndex = findScaleIndex(scaleName);
    if (scaleIndex == -1) {
        Serial.println("Scale not found!");
        return 0;
    }

    ScalePattern& scale = scales[scaleIndex];
    int current = root;
    output[0] = current;
    int count = 1;

    for (int i = 0; i < scale.length; i++) {
        current = (current + scale.intervals[i]) % 12;
        output[count++] = current;
        if (count >= MAX_SCALE_NOTES) break;
    }

    // Debug print to Serial
    Serial.print("Generated ");
    Serial.print(scaleName);
    Serial.print(" scale: ");
    for (int i = 0; i < count; i++) {
        Serial.print(noteNames[output[i]]);
        Serial.print(" ");
    }
    Serial.println();

    Serial.print("Note indices: ");
    for (int i = 0; i < count; i++) {
        Serial.print(output[i]);
        Serial.print(" ");
    }
    Serial.println();

    return count;
}

// Generate a chord
int generateChord(int root, const char* chordType, int* output) {
    int scaleNotes[MAX_SCALE_NOTES];
    int scaleCount = generateScale(root, chordType, scaleNotes);
    
    if (scaleCount < 5) {
        Serial.println("Not enough notes for chord!");
        return 0;
    }

    output[0] = root;           // root
    output[1] = scaleNotes[2];  // third
    output[2] = scaleNotes[4];  // fifth
    
    int chordCount = 3;

    // Debug print to Serial
    Serial.print("Generated ");
    Serial.print(chordType);
    Serial.print(" chord: ");
    for (int i = 0; i < chordCount; i++) {
        Serial.print(noteNames[output[i]]);
        Serial.print(" ");
    }
    Serial.println();

    Serial.print("Chord indices: ");
    for (int i = 0; i < chordCount; i++) {
        Serial.print(output[i]);
        Serial.print(" ");
    }
    Serial.println();

    return chordCount;
}