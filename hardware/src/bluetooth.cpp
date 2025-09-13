#include <Arduino.h>
#include "bluetooth.h"
#include "main.h"
#include "scale_and_chord_notes.h"

// Define globals here (once)
BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;

// Helper function to parse string (simple tokenizer)
void parseCommand(String value, String* tokens, int* tokenCount) {
  *tokenCount = 0;
  int start = 0;
  int end = value.indexOf(' ');
  
  while (end != -1 && *tokenCount < 5) {
    tokens[(*tokenCount)++] = value.substring(start, end);
    start = end + 1;
    end = value.indexOf(' ', start);
  }
  
  if (start < value.length()) {
    tokens[(*tokenCount)++] = value.substring(start);
  }

  for (int i = 0; i < *tokenCount; i++) {
    tokens[i].trim();
    Serial.print("Token ");
    Serial.print(i);
    Serial.print(": ");
    Serial.println(tokens[i]);
  }
}

class MyCharacteristicCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) override {
    String value = String(pCharacteristic->getValue().c_str());
    
    // Parse the command
    String tokens[5];
    int tokenCount;
    parseCommand(value, tokens, &tokenCount);
    
    // Print each token
    for (int i = 0; i < tokenCount; i++) {
      Serial.println(tokens[i]);
    }
    
    if (value.length() > 0) {
      Serial.print("[");
      Serial.print(millis() / 1000);
      Serial.print("s] Received: ");
      Serial.print(value);

      if(tokens[1] == "Major" || tokens[1] == "Minor" && tokens[0].toInt() >=0 && tokens[0].toInt() <=11) {
        Serial.print(" ");
        Serial.print(tokens[1]);
        Serial.println(" Chord Selected");
        
        int chordNotes[MAX_CHORD_NOTES];
        int noteCount = generateChord(tokens[0].toInt(), tokens[1].c_str(), chordNotes);
        
        for (int i = 0; i < noteCount; i++)
        {
          Serial.print(noteNames[chordNotes[i]]);
          Serial.print(" ");
        }
        Serial.println();
        
        int lightPixels[MAX_PIXELS];
        int pixelCount = pixelCalculator(chordNotes, noteCount, lightPixels);
        
        // Set grid color based on chord type
        Serial.print("Lighting up pixels for chord: ");
        Serial.print(tokens[0]);
        Serial.print(" ");
        Serial.println(tokens[1]);
        
        CRGB color = (tokens[1] == "Major") ? CRGB::Blue : CRGB::Red;
        setGridColor(lightPixels, pixelCount, color);
        delay(1000);

        // Clear the grid after displaying the scale
        // clearGrid();

      } else {
        Serial.println(" Unknown Chord Selected");
      }
      Serial.println();
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