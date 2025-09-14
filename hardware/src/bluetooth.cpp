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
    int tokenCount = parseCommand(value, tokens, 6);

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