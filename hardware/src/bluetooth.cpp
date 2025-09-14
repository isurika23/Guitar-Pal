#include <Arduino.h>
#include "bluetooth.h"
#include "main.h"
#include "scale_and_chord_notes.h"
#include "pixel_mapping.h"
#include "data_handling.h"

// Define globals here (once)
BLEServer *pServer = nullptr;
BLECharacteristic *pInitCharacteristic = nullptr;
BLECharacteristic *pChordPixelCharacteristic = nullptr;
BLECharacteristic *pScalePixelCharacteristic = nullptr;

class InitCharacteristicCallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic) override
  {
    String value = String(pCharacteristic->getValue().c_str());
    Serial.println("Init service received: " + value);
    
    // Handle initialization messages from mobile app
    if (value == "Guitar-Pal") {
      Serial.println("Mobile app connected and initialized");
      pCharacteristic->setValue("ESP32 Ready");
    }
  }
};

class ChordPixelCharacteristicCallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic) override
  {
    String value = String(pCharacteristic->getValue().c_str());
    Serial.println("Chord pixel service received: " + value);

    // Handle chord data from mobile app
    int tokens[6];
    int tokenCount = parseChordCommand(value, tokens, 6);

    if (tokenCount > 0)
    {
      Serial.print("[");
      Serial.print(millis() / 1000);
      Serial.print("s] Received chord data: ");
      Serial.print(value);

      // Process chord data (expecting 6 fret positions for chord)
      if (tokenCount == 6)
      {
        Serial.println(" - Processing chord positions");
        int pixels[6];
        clearGrid();
        convertChordPositionsToPixels(tokens, pixels);
        FastLED.show();
      }
      else
      {
        Serial.println(" - Invalid chord data format (expected 6 positions)");
      }
      Serial.println();
    }
  }
};

class ScalePixelCharacteristicCallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic) override
  {
    String value = String(pCharacteristic->getValue().c_str());
    Serial.println("Scale pixel service received: " + value);
    
    // Scale calculations not implemented yet
    Serial.println("Scale feature not implemented yet");

    // tokens is a nested array of 2 integer element array: string and fret
    int scaleData[20][2]; // Array to hold up to 20 string-fret pairs
    int scaleCount = parseScaleCommand(value, scaleData, 20);
    Serial.print("Parsed scale count: ");
    Serial.println(scaleCount);
    Serial.println("Scale data:");
    for (int i = 0; i < scaleCount; i++)
    {
      int guitarString = scaleData[i][0];
      int fretPosition = scaleData[i][1];
      int gridPosition = fretPosition * 6 + guitarString; // Convert to grid position

      Serial.print("Scale position ");
      Serial.print(i);
      Serial.print(": String ");
      Serial.print(guitarString);
      Serial.print(", Fret ");
      Serial.print(fretPosition);
      Serial.print(" -> Grid position ");
      Serial.println(gridPosition);

      // For debugging: print the corresponding LED index
      if (gridPosition < VALID_LEDS)
      {
        Serial.print("LED Index: ");
        Serial.println(fretLEDs[gridPosition]);
        // clearGrid();
        // FastLED.leds()[fretLEDs[gridPosition]] = CRGB::Blue; // Light up the corresponding LED in blue
        // FastLED.show();
        // delay(200); // Briefly show each LED for debugging
      }
      else
      {
        Serial.println("Grid position exceeds valid LED range");
      }

      // For debugging: print the corresponding LED index
    }

    if (scaleCount > 0)
    {
      Serial.print("[");
      Serial.print(millis() / 1000);
      Serial.print("s] Received scale data: ");
      Serial.print(value);
      Serial.print(" - Processing ");
      Serial.print(scaleCount);
      Serial.println(" scale positions");

      // Process scale data
      clearGrid();
      convertScalePositionsToPixels(scaleData, scaleCount);
      // FastLED.show();
    }
    else
    {
      Serial.println(" - Invalid scale data format");
    }


  }
};

void setupBluetooth()
{
  Serial.begin(115200);

  // Initialize BLE
  BLEDevice::init("ESP32_Isurika");

  // Print BLE MAC Address
  // uint8_t *mac = *BLEDevice::getAddress().getNative();
  // Serial.print("BLE MAC Address: ");
  // for (int i = 0; i < 6; i++)
  // {
  //   if (mac[i] < 16)
  //     Serial.print("0");
  //   Serial.print(mac[i], HEX);
  //   if (i < 5)
  //     Serial.print(":");
  // }
  // Serial.println();

  // Create BLE Server
  pServer = BLEDevice::createServer();

  // Create Init Service
  BLEService *pInitService = pServer->createService(INIT_SERVICE_UUID);
  
  // Create Init Characteristic
  pInitCharacteristic = pInitService->createCharacteristic(
      INIT_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  pInitCharacteristic->addDescriptor(new BLE2902());
  pInitCharacteristic->setCallbacks(new InitCharacteristicCallbacks());
  pInitCharacteristic->setValue("ESP32 Init Ready");

  // Create Pixel Service
  BLEService *pPixelService = pServer->createService(PIXEL_SERVICE_UUID);
  
  // Create Chord Pixel Characteristic
  pChordPixelCharacteristic = pPixelService->createCharacteristic(
      CHORD_PIXEL_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  pChordPixelCharacteristic->addDescriptor(new BLE2902());
  pChordPixelCharacteristic->setCallbacks(new ChordPixelCharacteristicCallbacks());
  pChordPixelCharacteristic->setValue("Chord Pixel Ready");

  // Create Scale Pixel Characteristic (for future use)
  pScalePixelCharacteristic = pPixelService->createCharacteristic(
      SCALE_PIXEL_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  pScalePixelCharacteristic->addDescriptor(new BLE2902());
  pScalePixelCharacteristic->setCallbacks(new ScalePixelCharacteristicCallbacks());
  pScalePixelCharacteristic->setValue("Scale Pixel Ready");

  // Start both services
  pInitService->start();
  pPixelService->start();

  // Start advertising both services
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(INIT_SERVICE_UUID);
  pAdvertising->addServiceUUID(PIXEL_SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06); // Helps with iPhone compatibility
  BLEDevice::startAdvertising();
  
  Serial.println("BLE Advertising Started");
  Serial.println("Init Service UUID: " + String(INIT_SERVICE_UUID));
  Serial.println("Pixel Service UUID: " + String(PIXEL_SERVICE_UUID));
  Serial.println("Waiting for mobile app connection...");
}