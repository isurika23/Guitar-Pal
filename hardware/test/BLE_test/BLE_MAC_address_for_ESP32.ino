#include <Arduino.h>
#include <BLEDevice.h>

void setup() {
  Serial.begin(115200);
  BLEDevice::init("ESP32_Isurika"); // Initialize BLE without setting a device name
  uint8_t* mac = *BLEDevice::getAddress().getNative(); // Get BLE MAC address
  
  Serial.print("BLE MAC Address: ");
  for (int i = 0; i < 6; i++) {
    if (mac[i] < 16) Serial.print("0"); // Add leading zero for single-digit hex
    Serial.print(mac[i], HEX);
    if (i < 5) Serial.print(":");
  }
  Serial.println();
}

void loop() {
  // Empty loop
}