#include <Arduino.h>
#include "data_handling.h"

// Helper function to parse string (simple tokenizer)
// Parse a comma-separated string into tokens, handling optional [ ] brackets
// tokens: pre-allocated String array to store tokens
// maxTokens: maximum number of tokens the array can hold
// tokenCount: pointer to integer to store the number of tokens found
int parseChordCommand(String value, int *tokens, int maxTokens)
{
    // Initialize token count
    int tokenCount = 0;
    // Serial.print(value);

    // Check for empty or invalid input
    if (value.length() == 0)
    {
        // Serial.println(" - Empty command");
        return 0;
    }

    int start = 0;
    int end = value.indexOf(',');

    // Skip opening bracket if present
    if (value.startsWith("["))
    {
        // Serial.println(" - Skipping opening bracket");
        start = 1;
    }

    while (end != -1 && tokenCount < maxTokens)
    {
        String temp = value.substring(start, end);
        temp.trim();
        tokens[tokenCount] = temp.toInt();
        // Serial.print(" - Found token: ");
        // Serial.println(temp);
        tokenCount++;
        start = end + 1;
        end = value.indexOf(',', start);
    }

    // Add the last token if there's space
    if (tokenCount < maxTokens)
    {
        String lastToken = value.substring(start);
        lastToken.trim();
        // Remove closing bracket if present
        // Serial.println(" - Found last token: " + lastToken + (lastToken.endsWith("]") ? " (with closing bracket)" : ""));
        if (lastToken.endsWith("]"))
        {
            lastToken = lastToken.substring(0, lastToken.length() - 1);
            lastToken.trim();
        }
        tokens[tokenCount] = lastToken.toInt();
        // Serial.print(" - Found last token: ");
        // Serial.println(lastToken);
        tokenCount++;
    }

    Serial.print("Parsed tokens: ");
    for (int i = 0; i < tokenCount; i++)
    {
        Serial.print(tokens[i]);
        if (i < tokenCount - 1)
            Serial.print(", ");
    }
    Serial.println();

    return tokenCount; // Return the actual token count
}

// Parse combined chord command with finger positions in O(n) time complexity
// Format: "[fret1, fret2, ..., fret6]|[finger1, finger2, ..., finger6]"
// fretTokens: array to store fret positions
// fingerTokens: array to store finger positions
// maxTokens: maximum tokens per array (should be 6 for guitar)
// Returns: number of tokens parsed (should be 6 if successful)
int parseChordCommandWithFingers(String value, int *fretTokens, int *fingerTokens, int maxTokens)
{
    Serial.print("Parsing chord command with fingers: ");
    Serial.println(value);

    // Check for empty input
    if (value.length() == 0)
    {
        Serial.println(" - Empty command");
        return 0;
    }

    // Find pipe separator to split fret and finger data
    int pipeIndex = value.indexOf('|');

    if (pipeIndex == -1)
    {
        // No pipe found, fall back to parsing as fret-only data
        Serial.println(" - No finger data found, parsing fret only");
        int fretCount = parseChordCommand(value, fretTokens, maxTokens);
        // Set all finger positions to -1 (no finger indication)
        for (int i = 0; i < fretCount; i++)
        {
            fingerTokens[i] = -1;
        }
        return fretCount;
    }

    // Extract fret and finger portions (single pass through string)
    String fretPart = value.substring(0, pipeIndex);
    String fingerPart = value.substring(pipeIndex + 1);

    fretPart.trim();
    fingerPart.trim();

    Serial.print(" - Fret part: ");
    Serial.println(fretPart);
    Serial.print(" - Finger part: ");
    Serial.println(fingerPart);

    // Parse both parts
    int fretCount = parseChordCommand(fretPart, fretTokens, maxTokens);
    int fingerCount = parseChordCommand(fingerPart, fingerTokens, maxTokens);

    // Validate that both arrays have same length
    if (fretCount != fingerCount)
    {
        Serial.print(" - Warning: fret count (");
        Serial.print(fretCount);
        Serial.print(") != finger count (");
        Serial.print(fingerCount);
        Serial.println(")");
    }

    Serial.print("Parsed fret positions: ");
    for (int i = 0; i < fretCount; i++)
    {
        Serial.print(fretTokens[i]);
        if (i < fretCount - 1)
            Serial.print(", ");
    }
    Serial.println();

    Serial.print("Parsed finger positions: ");
    for (int i = 0; i < fingerCount; i++)
    {
        Serial.print(fingerTokens[i]);
        if (i < fingerCount - 1)
            Serial.print(", ");
    }
    Serial.println();

    return fretCount;
}

int parseScaleCommand(String value, int scaleData[][2], int maxPairs)
{
    int pairCount = 0;
    // Serial.print("Parsing scale command: ");
    // Serial.println(value);

    // Check for empty or invalid input
    if (value.length() == 0)
    {
        Serial.println(" - Empty scale command");
        return 0;
    }

    // Remove outer brackets if present
    String cleanValue = value;
    cleanValue.trim();
    if (cleanValue.startsWith("[") && cleanValue.endsWith("]"))
    {
        cleanValue = cleanValue.substring(1, cleanValue.length() - 1);
        cleanValue.trim();
    }

    // Check if this is a simple pair format: "string, fret" (after removing outer brackets)
    // This happens when sending a single note like [2, 3]
    if (cleanValue.indexOf('[') == -1)
    {
        // Simple format: "string, fret" - parse directly as single pair
        int commaPos = cleanValue.indexOf(',');
        if (commaPos != -1 && pairCount < maxPairs)
        {
            String firstNum = cleanValue.substring(0, commaPos);
            String secondNum = cleanValue.substring(commaPos + 1);
            firstNum.trim();
            secondNum.trim();

            scaleData[pairCount][0] = firstNum.toInt();  // string
            scaleData[pairCount][1] = secondNum.toInt(); // fret

            Serial.print("Parsed single pair: [");
            Serial.print(scaleData[pairCount][0]);
            Serial.print(", ");
            Serial.print(scaleData[pairCount][1]);
            Serial.println("]");

            pairCount++;
        }

        Serial.print("Total parsed scale pairs: ");
        Serial.println(pairCount);
        return pairCount;
    }

    // Parse nested arrays like [[5, 5], [5, 7], [5, 9]]
    int start = 0;
    while (start < cleanValue.length() && pairCount < maxPairs)
    {
        // Find start of next pair
        int pairStart = cleanValue.indexOf('[', start);
        if (pairStart == -1)
            break;

        // Find end of current pair
        int pairEnd = cleanValue.indexOf(']', pairStart);
        if (pairEnd == -1)
            break;

        // Extract pair content
        String pairContent = cleanValue.substring(pairStart + 1, pairEnd);
        pairContent.trim();

        // Parse the two integers in the pair
        int commaPos = pairContent.indexOf(',');
        if (commaPos != -1)
        {
            String firstNum = pairContent.substring(0, commaPos);
            String secondNum = pairContent.substring(commaPos + 1);
            firstNum.trim();
            secondNum.trim();

            scaleData[pairCount][0] = firstNum.toInt();  // string
            scaleData[pairCount][1] = secondNum.toInt(); // fret

            Serial.print("Parsed pair ");
            Serial.print(pairCount);
            Serial.print(": [");
            Serial.print(scaleData[pairCount][0]);
            Serial.print(", ");
            Serial.print(scaleData[pairCount][1]);
            Serial.println("]");

            pairCount++;
        }

        start = pairEnd + 1;
    }

    Serial.print("Total parsed scale pairs: ");
    Serial.println(pairCount);
    return pairCount;
}
