#include <Arduino.h>
#include "bluetooth.h"
#include "main.h"
#include "scale_and_chord_notes.h" // Include the scale and chord generation code

// Define globals here (once)
BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;

class MyCharacteristicCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) override {
    // how value type got to string?
    std::string value = pCharacteristic->getValue();
    if (!value.empty()) {
      Serial.print("[");
      Serial.print(millis() / 1000);
      Serial.print("s] Received: ");
      for (char c : value) {
        Serial.print(c);
      }
      if(value == "Major"){
        Serial.println(" Major Chord Selected");
        std::vector<int> chordNotes = generateChord(0, "Major");
        for (int note : chordNotes)
        {
          Serial.print(noteNames[note]);
          Serial.print(" ");
        }
        Serial.println();
        std::vector<int> lightPixel = pixelCalculator(chordNotes);
        // Set grid color to blue for the major scale
        Serial.print("Lighting up pixels for chord: ");
        Serial.println("C Major");
        setGridColor(lightPixel, CRGB::Blue);
        delay(1000);

  // Clear the grid after displaying the scale
  clearGrid();

      } else if(value == "Minor"){
        Serial.println(" Minor Chord Selected");
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
