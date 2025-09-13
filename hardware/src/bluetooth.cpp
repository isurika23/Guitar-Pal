#include <Arduino.h>
#include "bluetooth.h"
#include "main.h"
#include "scale_and_chord_notes.h"
#include "pixel_mapping.h"
#include "data_handling.h"

// Define globals here (once)
BLEServer *pServer = nullptr;
BLECharacteristic *pCharacteristic = nullptr;

class MyCharacteristicCallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic) override
  {
    String value = String(pCharacteristic->getValue().c_str());
    Serial.println("Raw received value: " + value);

    // Simple parsing: expecting "[1, 3, 5, 6, 9, 23]" or array of positions
    if (value != "Guitar-Pal")
    {
      int tokens[6];
      int tokenCount = parseCommand(value, tokens, 6); // Pass 6 as maxTokens

      // Serial.print("Token count: ");
      // Serial.println(tokenCount);

      if (tokenCount > 0)
      {
        Serial.print("[");
        Serial.print(millis() / 1000);
        Serial.print("s] Received: ");
        Serial.print(value);

        // Check if it's a chord command (first token is note, second is Major/Minor)
        if (tokenCount == 6)
        {

          int pixels[6];
          clearGrid();
          convertChordPositionsToPixels(tokens, pixels);
          FastLED.show();
        }
        else
        {
          Serial.println(" - Invalid command format");
        }
        Serial.println();
      }
    }
  }
};

void setupBluetooth()
{
  Serial.begin(115200);

  // Initialize BLE
  BLEDevice::init("ESP32_Isurika");

  // Print BLE MAC Address
  uint8_t *mac = *BLEDevice::getAddress().getNative();
  Serial.print("BLE MAC Address: ");
  for (int i = 0; i < 6; i++)
  {
    if (mac[i] < 16)
      Serial.print("0");
    Serial.print(mac[i], HEX);
    if (i < 5)
      Serial.print(":");
  }
  Serial.println();

  // Create BLE Server
  pServer = BLEDevice::createServer();

  // Create BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create BLE Characteristic
  pCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setCallbacks(new MyCharacteristicCallbacks());

  // Set a default value
  pCharacteristic->setValue("Hello from ESP32!");

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06); // Helps with iPhone compatibility
  BLEDevice::startAdvertising();
  Serial.println("BLE Advertising Started");
}