#include <Arduino.h>
#include "data_handling.h"

// Helper function to parse string (simple tokenizer)
// Parse a comma-separated string into tokens, handling optional [ ] brackets
// tokens: pre-allocated String array to store tokens
// maxTokens: maximum number of tokens the array can hold
// tokenCount: pointer to integer to store the number of tokens found
int parseCommand(String value, int *tokens, int maxTokens)
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
