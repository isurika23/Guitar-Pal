#ifndef SCALE_AND_CHORD_NOTES_H
#define SCALE_AND_CHORD_NOTES_H

#include <string>
#include <vector>
#include <map>

// extern = defined elsewhere, not duplicated
extern std::map<std::string, std::vector<int>> scales;
extern const char* noteNames[12];

// Function declarations
std::vector<int> generateScale(int root, const std::string& scaleName);
std::vector<int> generateChord(int root, const std::string& chordType);

#endif