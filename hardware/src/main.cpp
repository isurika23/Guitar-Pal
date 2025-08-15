#include <Arduino.h>
#include <FastLED.h>
#define DATA_PIN 4
#define NUM_LEDS 64 // 8x8 grid
// CRGB leds[NUM_LEDS];
#define VALID_LEDS 48
CRGB leds[NUM_LEDS];
int fretLEDs[VALID_LEDS];

// for grid board setup;
void setGridPixeltoFrets(){
  int fretLEDcount = 0;
  for (int i = 0; i < NUM_LEDS; i++){
    if (i % 8 < 6){
      fretLEDs[fretLEDcount] = i;
      fretLEDcount++;
    // } else {
      
    }
  }
};

void setGridColor(CRGB color) {
  for (int i = 0; i < VALID_LEDS; i++) {
    leds[fretLEDs[i]] = color;
    FastLED.show();
    delay(500);
  }
}

void setup() {
  FastLED.addLeds<WS2812B, DATA_PIN, GRB>(leds, NUM_LEDS);
  FastLED.setBrightness(20); // Low brightness (~1.28 A)
  Serial.begin(115200);
  setGridPixeltoFrets(); // Initialize the grid with valid LED positions
  Serial.println("Testing WS2812B 8x8 LED Grid (64 LEDs)");
}

void loop() {
  setGridColor(CRGB(255, 0, 0)); // Red
  Serial.println("All LEDs Red");
  delay(1000);

  setGridColor(CRGB(0, 255, 0)); // Green
  Serial.println("All LEDs Green");
  delay(1000);

  setGridColor(CRGB(0, 0, 255)); // Blue
  Serial.println("All LEDs Blue");
  delay(1000);

  // setGridColor(CRGB(0, 0, 0)); // Off
  // Serial.println("All LEDs Off");
  // delay(1000);
}