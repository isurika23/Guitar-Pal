#ifndef BLUETOOTH_H
#define BLUETOOTH_H

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define INIT_SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define INIT_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// UUIDs for pixel mapping service and characteristics
// These should match the UUIDs used in the Flutter app
#define PIXEL_SERVICE_UUID "c3c50c29-d4a5-4998-b382-62dcc1845e10"
#define CHORD_PIXEL_CHAR_UUID "c3c50c29-d4a5-4998-b382-62dcc1845e11"
#define SCALE_PIXEL_CHAR_UUID "c3c50c29-d4a5-4998-b382-62dcc1845e12"

// Declare global BLE objects (definition goes in .cpp)
extern BLEServer *pServer;
extern BLECharacteristic *pInitCharacteristic;
extern BLECharacteristic *pChordPixelCharacteristic;
extern BLECharacteristic *pScalePixelCharacteristic;

// Function prototypes
void setupBluetooth();

#endif // BLUETOOTH_H
