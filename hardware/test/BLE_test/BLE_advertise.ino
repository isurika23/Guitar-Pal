#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// Define BLE service and characteristic UUIDs (must match the Flutter app)
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;

class MyCharacteristicCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    String value = pCharacteristic->getValue(); // Use String as per previous fix
    if (value.length() > 0) {
      Serial.print("[");
      Serial.print(millis() / 1000); // Timestamp in seconds since boot
      Serial.print("s] Received: ");
      for (int i = 0; i < value.length(); i++) {
        Serial.print(value[i]);
      }
      Serial.println();
    }
  }
};

void setup() {
  Serial.begin(115200);

  // Initialize BLE
  BLEDevice::init("ESP32_Isurika"); // Set device name for advertisement

  // Print BLE MAC Address for reference
  uint8_t* mac = *BLEDevice::getAddress().getNative(); // Get BLE MAC address
  Serial.print("BLE MAC Address: ");
  for (int i = 0; i < 6; i++) {
    if (mac[i] < 16) Serial.print("0"); // Add leading zero for single-digit hex
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
  pCharacteristic->addDescriptor(new BLE2902()); // Enable notifications
  pCharacteristic->setCallbacks(new MyCharacteristicCallbacks()); // Set callback for writes

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

void loop() {
  // Handle BLE events
  delay(1000);
}