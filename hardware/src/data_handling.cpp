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
    Serial.print(value);

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

int parseScaleCommand(String value, int scaleData[][2], int maxPairs)
{
    int pairCount = 0;
    Serial.print("Parsing scale command: ");
    Serial.println(value);

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

    // Parse nested arrays like [5, 5], [5, 7], [5, 9]
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
