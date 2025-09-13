#include <Arduino.h>
#include "bluetooth.h"
#include "main.h"
#include "scale_and_chord_notes.h"

// Define globals here (once)
BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;

void convertStringPositionsToPixels(int* stringPositions, int* pixels) {
  int pixelCount = 0;
  
  for (int string = 0; string < 6; string++) {
    int fretPosition = stringPositions[string];
    
    // Skip if no LED should be lit for this string (position 0)
    if (fretPosition <= 0) {
      if(fretPosition < 0){
        Serial.print("Don't strum string: ");
        Serial.println(string);
        pixels[pixelCount] = string; // Indicate no strum for this string
        leds[fretLEDs[pixels[pixelCount]]] = CRGB::Red; // Use red for muted strings
        pixelCount++;
      } else if (fretPosition == 0) {
        Serial.print("Open string: ");
        Serial.println(string);
        pixels[pixelCount] = string; // Indicate open string for this string
        leds[fretLEDs[pixels[pixelCount]]] = CRGB::Green; // Use green for open strings
        pixelCount++;
      }
      continue;
    }
    
    // Convert to grid position
    // fretPosition 1 = fret 0 (open string) = LED indices 0-5
    // fretPosition 2 = fret 1 = LED indices 6-11, etc.
    int gridPosition = (fretPosition) * 6 + string;
    
    // Make sure we don't exceed the valid LED range
    if (gridPosition < VALID_LEDS) {
      pixels[pixelCount] = gridPosition;
      leds[fretLEDs[gridPosition]] = CRGB::Blue; // Use blue for normal strummed strings
      pixelCount++;
      
      Serial.print("String ");
      Serial.print(string);
      Serial.print(", Position ");
      Serial.print(fretPosition);
      Serial.print(" -> Grid position ");
      Serial.println(gridPosition);
    }
  }
  
  return;
}

// Helper function to parse string (simple tokenizer)
// Parse a comma-separated string into tokens, handling optional [ ] brackets
// tokens: pre-allocated String array to store tokens
// maxTokens: maximum number of tokens the array can hold
// tokenCount: pointer to integer to store the number of tokens found
int parseCommand(String value, int* tokens, int maxTokens) {
  // Initialize token count
  int tokenCount = 0;
  Serial.print(value);

  // Check for empty or invalid input
  if (value.length() == 0) {
    // Serial.println(" - Empty command");
    return 0;
  }

  int start = 0;
  int end = value.indexOf(',');

  // Skip opening bracket if present
  if (value.startsWith("[")) {
    // Serial.println(" - Skipping opening bracket");
    start = 1;
  }

  while (end != -1 && tokenCount < maxTokens) {
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
  if (tokenCount < maxTokens) {
    String lastToken = value.substring(start);
    lastToken.trim();
    // Remove closing bracket if present
    // Serial.println(" - Found last token: " + lastToken + (lastToken.endsWith("]") ? " (with closing bracket)" : ""));
    if (lastToken.endsWith("]")) {
      lastToken = lastToken.substring(0, lastToken.length() - 1);
      lastToken.trim();
    }
    tokens[tokenCount] = lastToken.toInt();
    // Serial.print(" - Found last token: ");
    // Serial.println(lastToken);
    tokenCount++;
  }

  Serial.print("Parsed tokens: ");
  for (int i = 0; i < tokenCount; i++) {
    Serial.print(tokens[i]);
    if (i < tokenCount - 1) Serial.print(", ");
  }
  Serial.println();
  
  return tokenCount; // Return the actual token count
}

class MyCharacteristicCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) override {
    String value = String(pCharacteristic->getValue().c_str());
    Serial.println("Raw received value: " + value);

    // Simple parsing: expecting "[1, 3, 5, 6, 9, 23]" or array of positions
    if(value != "Guitar-Pal") {
      int tokens[6];
      int tokenCount = parseCommand(value, tokens, 6); // Pass 6 as maxTokens

      // Serial.print("Token count: ");
      // Serial.println(tokenCount);

      if (tokenCount > 0) {
        Serial.print("[");
        Serial.print(millis() / 1000);
        Serial.print("s] Received: ");
        Serial.print(value);

        // Check if it's a chord command (first token is note, second is Major/Minor)
        if (tokenCount == 6) {
         
          int pixels[6];
          clearGrid();
          convertStringPositionsToPixels(tokens, pixels);
          FastLED.show();
        } else {
          Serial.println(" - Invalid command format");
          

        }
        Serial.println();
      }
    
    }
  }
};

void setupBluetooth() {
  Serial.begin(115200);

  // Initialize BLE
  BLEDevice::init("ESP32_Isurika");

  // Print BLE MAC Address
  uint8_t* mac = *BLEDevice::getAddress().getNative();
  Serial.print("BLE MAC Address: ");
  for (int i = 0; i < 6; i++) {
    if (mac[i] < 16) Serial.print("0");
    Serial.print(mac[i], HEX);
    if (i < 5) Serial.print(":");
  }
  Serial.println();

  // Create BLE Server
  pServer = BLEDevice::createServer();

  // Create BLE Service
  BLEService* pService = pServer->createService(SERVICE_UUID);

  // Create BLE Characteristic
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE
                    );
  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setCallbacks(new MyCharacteristicCallbacks());

  // Set a default value
  pCharacteristic->setValue("Hello from ESP32!");

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06); // Helps with iPhone compatibility
  BLEDevice::startAdvertising();
  Serial.println("BLE Advertising Started");
}