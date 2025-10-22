#ifndef PIXEL_MAPPING_H
#define PIXEL_MAPPING_H

// Function to convert chord string positions to LED pixel positions
void convertChordPositionsToPixels(int *stringPositions, int *pixels);

// Function to convert chord positions with finger information to LED pixels with color coding
void convertChordPositionsToPixelsWithFingers(int *fretPositions, int *fingerPositions);

// Function to convert scale positions to LED pixel positions
void convertScalePositionsToPixels(int scaleData[][2], int scaleCount);

#endif // PIXEL_MAPPING_H
