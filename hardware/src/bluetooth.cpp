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
BLECharacteristic *pClearPixelCharacteristic = nullptr;
BLECharacteristic *pWrongPositionCharacteristic = nullptr;

class InitCharacteristicCallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic) override
  {
    String value = String(pCharacteristic->getValue().c_str());
    Serial.println("Init service received: " + value);

    // Handle initialization messages from mobile app
    if (value == "Guitar-Pal")
    {
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

    // Handle chord data from mobile app with finger positions
    int fretTokens[6];
    int fingerTokens[6];
    int tokenCount = parseChordCommandWithFingers(value, fretTokens, fingerTokens, 6);

    if (tokenCount > 0)
    {
      Serial.print("[");
      Serial.print(millis() / 1000);
      Serial.print("s] Received chord data: ");
      Serial.print(value);

      // Process chord data (expecting 6 fret positions and 6 finger positions)
      if (tokenCount == 6)
      {
        Serial.println(" - Processing chord positions with finger colors");
        
        // Update expected positions for finger detection
        updateExpectedPositions(fretTokens, fingerTokens);
        
        clearGrid();
        convertChordPositionsToPixelsWithFingers(fretTokens, fingerTokens);
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

    // Check for clear command first
    if (value.equalsIgnoreCase("clear") || value == "[]")
    {
      Serial.println("Clearing scale LEDs");
      clearGrid();
      FastLED.show();
      return;
    }

    // New format: Single note position "[string, fret]" sent by mobile app at BPM interval
    // Mobile app controls timing and direction, ESP32 just displays

    // Parse single note position [string, fret]
    int scaleData[1][2]; // Single note
    int scaleCount = parseScaleCommand(value, scaleData, 1);

    if (scaleCount == 1)
    {
      int guitarString = scaleData[0][0];
      int fretPosition = scaleData[0][1];

      Serial.print("Lighting note: String ");
      Serial.print(guitarString);
      Serial.print(", Fret ");
      Serial.println(fretPosition);

      // Validate string and fret
      if (guitarString >= 0 && guitarString < 6 && fretPosition >= 0 && fretPosition < 7)
      {
        int gridPosition = fretPosition * 6 + guitarString;

        if (gridPosition < NUM_LEDS)
        {
          // Light up the single note in green (active note color)
          leds[fretLEDs[gridPosition]] = CRGB::Green;
          FastLED.show();

          Serial.print("LED Grid position ");
          Serial.print(gridPosition);
          Serial.print(" -> Physical LED ");
          Serial.println(fretLEDs[gridPosition]);
        }
      }
      else
      {
        Serial.println("Invalid string or fret position");
      }
    }
    else
    {
      Serial.println("Invalid scale data format - expected single [string, fret] pair");
    }
  }
};

class ClearPixelCharacteristicCallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic) override
  {
    String value = String(pCharacteristic->getValue().c_str());
    Serial.print("Clear pixel service received: ");
    Serial.println(value);

    // Any non-empty message to this characteristic clears the display
    // This provides a dedicated channel for clearing LEDs
    if (value.length() > 0)
    {
      Serial.println("Clearing all LEDs via dedicated clear characteristic");
      clearGrid();
      FastLED.show();
    }
  }
};

// Server callback class to handle connection events
class MyServerCallbacks : public BLEServerCallbacks
{
  void onConnect(BLEServer *pServer) override
  {
    Serial.println("Client connected");
    digitalWrite(BL_CONNECTED_PIN, HIGH);
    digitalWrite(BL_DISCONNECTED_PIN, LOW);
  }

  void onDisconnect(BLEServer *pServer) override
  {
    Serial.println("Client disconnected - Restarting advertising");
    delay(500);                  // Give some time for cleanup
    pServer->startAdvertising(); // Restart advertising
    Serial.println("BLE Advertising restarted - Ready for new connection");
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

  // Set server callbacks to handle connection events
  pServer->setCallbacks(new MyServerCallbacks());

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

  // Create Scale Pixel Characteristic
  pScalePixelCharacteristic = pPixelService->createCharacteristic(
      SCALE_PIXEL_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  pScalePixelCharacteristic->addDescriptor(new BLE2902());
  pScalePixelCharacteristic->setCallbacks(new ScalePixelCharacteristicCallbacks());
  pScalePixelCharacteristic->setValue("Scale Pixel Ready");

  // Create Clear Pixel Characteristic - dedicated channel for clearing LEDs
  pClearPixelCharacteristic = pPixelService->createCharacteristic(
      CLEAR_PIXEL_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  pClearPixelCharacteristic->addDescriptor(new BLE2902());
  pClearPixelCharacteristic->setCallbacks(new ClearPixelCharacteristicCallbacks());
  pClearPixelCharacteristic->setValue("Clear Pixel Ready");

  // Create Wrong Position Characteristic - for notifying mobile app of wrong finger positions
  pWrongPositionCharacteristic = pPixelService->createCharacteristic(
      WRONG_POSITION_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pWrongPositionCharacteristic->addDescriptor(new BLE2902());
  pWrongPositionCharacteristic->setValue("[]"); // Initially no wrong positions

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

/// Send wrong position data to mobile app via BLE notification
/// Format: [[string, fret], [string, fret], ...] or [] if no wrong positions
void sendWrongPositions(String wrongPosData)
{
  if (pWrongPositionCharacteristic != nullptr && pServer != nullptr && pServer->getConnectedCount() > 0)
  {
    // Only send if data has changed to reduce BLE traffic
    static String lastSentData = "";
    if (wrongPosData != lastSentData)
    {
      pWrongPositionCharacteristic->setValue(wrongPosData.c_str());
      pWrongPositionCharacteristic->notify();
      lastSentData = wrongPosData;
      
      if (wrongPosData != "[]")
      {
        Serial.print("Sent wrong positions to mobile app: ");
        Serial.println(wrongPosData);
      }
    }
  }
}

/// Update expected finger positions from received chord data
/// Stores fret and finger positions in global arrays for comparison
void updateExpectedPositions(int *fretPositions, int *fingerPositions)
{
  Serial.println("Updating expected finger positions...");
  for (int i = 0; i < 6; i++)
  {
    expectedFretPos[i] = fretPositions[i];
    expectedFingerPos[i] = fingerPositions[i];
    
    Serial.print("String ");
    Serial.print(i);
    Serial.print(": Fret ");
    Serial.print(expectedFretPos[i]);
    Serial.print(", Finger ");
    Serial.println(expectedFingerPos[i]);
  }
  Serial.println("Expected positions updated");
}