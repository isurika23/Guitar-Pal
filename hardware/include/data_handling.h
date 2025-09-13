#ifndef DATA_HANDLING_H
#define DATA_HANDLING_H

#include <Arduino.h>

// Function to parse comma-separated string into integer tokens
int parseCommand(String value, int *tokens, int maxTokens);

#endif // DATA_HANDLING_H
