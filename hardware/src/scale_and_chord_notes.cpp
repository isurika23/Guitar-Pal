#include "scale_and_chord_notes.h"
#include <Arduino.h>  // For Serial on ESP32

// Intervals
const int T = 2;
const int S = 1;

// Scale definitions
std::map<std::string, std::vector<int>> scales = {
    {"Major", {T, T, S, T, T, T, S}},
    {"Minor", {T, S, T, T, S, T, T}},
    {"Diminished Whole-Half", {T, S, T, S, T, S, T, S}},
    {"Diminished Half-Whole", {S, T, S, T, S, T, S, T}}
};

const char* noteNames[12] = {
  "C", "C#", "D", "D#", "E", "F",
  "F#", "G", "G#", "A", "A#", "B"
};

// Generate a scale
std::vector<int> generateScale(int root, const std::string& scaleName) {
    std::vector<int> result;
    int current = root;
    result.push_back(current);

    for (int step : scales[scaleName]) {
        current = (current + step) % 12;
        result.push_back(current);
    }

    // Debug print to Serial
    Serial.print("Generated ");
    Serial.print(scaleName.c_str());
    Serial.print(" scale: ");
    for (int note : result) {
        Serial.print(noteNames[note]);
        Serial.print(" ");
    }
    Serial.println();

    Serial.print("Note indices: ");
    for (int note : result) {
        Serial.print(note);
        Serial.print(" ");
    }
    Serial.println();

    return result;
}

// Generate a chord
std::vector<int> generateChord(int root, const std::string& chordType) {
    std::vector<int> chord;
    std::vector<int> scale = generateScale(root, chordType);

    chord.push_back(root);
    chord.push_back(scale[2]); // third
    chord.push_back(scale[4]); // fifth

    // Debug print to Serial
    Serial.print("Generated ");
    Serial.print(chordType.c_str());
    Serial.print(" chord: ");
    for (int note : chord) {
        Serial.print(noteNames[note]);
        Serial.print(" ");
    }
    Serial.println();

    Serial.print("Chord indices: ");
    for (int note : chord) {
        Serial.print(note);
        Serial.print(" ");
    }
    Serial.println();

    return chord;
}
