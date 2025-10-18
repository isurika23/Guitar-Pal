import 'package:flutter/material.dart';

/// A reusable fretboard widget that displays finger positions for chords and scales
class FretboardWidget extends StatelessWidget {
  final List<int> fretPositions;
  final List<int> fingerPositions;
  final List<String> noStrumStrings;
  final String title;
  final bool isScaleMode;
  final List<List<int>>? scalePositions;
  final String? selectedNote;
  final String selectedType;
  final List<String> notes;

  const FretboardWidget({
    required this.fretPositions,
    this.fingerPositions = const [],
    this.noStrumStrings = const [],
    this.title = "Fretboard",
    this.isScaleMode = false,
    this.scalePositions,
    required this.selectedNote,
    required this.selectedType,
    required this.notes,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chord/Scale name with smooth transition
          AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: Text(
              selectedNote == null
                  ? "Select a ${isScaleMode ? 'scale' : 'chord'}"
                  : "$selectedNote $selectedType",
              key: ValueKey(
                selectedNote == null ? 'none' : '$selectedNote-$selectedType',
              ),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: selectedNote == null ? Colors.grey : Colors.black,
              ),
            ),
          ),
          SizedBox(height: 8),

          // Notes display - always keep space, show empty if nothing selected
          SizedBox(
            height: 26, // Fixed height to maintain layout
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: Text(
                selectedNote != null && notes.isNotEmpty ? notes.join(" ") : "",
                key: ValueKey(notes.join("-")),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Fretboard visualization
          _buildFretboard(),

          // Finger legend - only show for chords (not scale mode)
          if (!isScaleMode && fingerPositions.isNotEmpty) _buildFingerLegend(),
        ],
      ),
    );
  }

  Widget _buildFingerLegend() {
    // Map of finger numbers to their colors and names
    final fingerInfo = {
      1: {'name': 'Index Finger', 'color': Color(0xFF4CAF50)}, // Green
      2: {'name': 'Middle Finger', 'color': Color(0xFF2196F3)}, // Blue
      3: {'name': 'Ring Finger', 'color': Color(0xFFFF9800)}, // Orange
      4: {'name': 'Pinky Finger', 'color': Color(0xFFE91E63)}, // Pink
    };

    return Container(
      margin: EdgeInsets.only(top: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Finger Guide:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: fingerInfo.entries.map((entry) {
              final fingerNum = entry.key;
              final name = entry.value['name'] as String;
              final color = entry.value['color'] as Color;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Colored circle with finger number
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        fingerNum.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Finger name
                  Text(
                    name,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFretboard() {
    return RepaintBoundary(
      child: Container(
        height: 450,
        width: double.infinity,
        child: CustomPaint(
          painter: FretboardPainter(
            fretPositions: fretPositions,
            fingerPositions: fingerPositions,
            noStrumStrings: noStrumStrings,
            isScaleMode: isScaleMode,
            scalePositions: scalePositions,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for drawing the fretboard
class FretboardPainter extends CustomPainter {
  final List<int> fretPositions;
  final List<int> fingerPositions;
  final List<String> noStrumStrings;
  final bool isScaleMode;
  final List<List<int>>? scalePositions;

  FretboardPainter({
    required this.fretPositions,
    this.fingerPositions = const [],
    required this.noStrumStrings,
    this.isScaleMode = false,
    this.scalePositions,
  });

  // Get color for each finger
  Color _getFingerColor(int fingerNum) {
    switch (fingerNum) {
      case 1:
        return Color(0xFF4CAF50); // Green - Index
      case 2:
        return Color(0xFF2196F3); // Blue - Middle
      case 3:
        return Color(0xFFFF9800); // Orange - Ring
      case 4:
        return Color(0xFFE91E63); // Pink - Pinky
      default:
        return Color(0xFF368BF4); // Default blue
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stringPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    final fretPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;

    final nutPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0;

    final fingerPaint = Paint()
      ..color = const Color.fromARGB(255, 54, 139, 244)
      ..style = PaintingStyle.fill;

    final openStringPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final noStrumPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0;

    // Guitar string names (from low E to high e, now left to right)
    final stringNames = ['E', 'A', 'D', 'G', 'B', 'E'];

    // Constants for fretboard layout (rotated: strings are vertical, frets are horizontal)
    const int numStrings = 6;
    const int numFrets = 6;
    final double topMargin = 60; // Space for string names at top
    final double bottomMargin = 40;
    final double sideMargin = 40;

    final double fretboardWidth = size.width - (sideMargin * 2);
    final double fretboardHeight = size.height - topMargin - bottomMargin;
    final double stringSpacing = fretboardWidth / (numStrings - 1);
    final double fretSpacing = fretboardHeight / numFrets;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw string names at the TOP of each string (above the fretboard)
    for (int i = 0; i < numStrings; i++) {
      final x = sideMargin + (i * stringSpacing);

      textPainter.text = TextSpan(
        text: stringNames[i],
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      // Position string names above each string line
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, topMargin - 30),
      );
    }

    // Draw strings (vertical lines)
    for (int i = 0; i < numStrings; i++) {
      final x = sideMargin + (i * stringSpacing);
      canvas.drawLine(
        Offset(x, topMargin),
        Offset(x, topMargin + fretboardHeight),
        stringPaint,
      );
    }

    // Draw nut (thick horizontal line at the top)
    canvas.drawLine(
      Offset(sideMargin, topMargin),
      Offset(sideMargin + fretboardWidth, topMargin),
      nutPaint,
    );

    // Draw frets (horizontal lines)
    for (int i = 1; i <= numFrets; i++) {
      final y = topMargin + (i * fretSpacing);
      canvas.drawLine(
        Offset(sideMargin, y),
        Offset(sideMargin + fretboardWidth, y),
        fretPaint,
      );
    }

    if (isScaleMode && scalePositions != null) {
      _drawScalePositions(
        canvas,
        size,
        topMargin,
        sideMargin,
        stringSpacing,
        fretSpacing,
      );
    } else {
      _drawChordPositions(
        canvas,
        size,
        topMargin,
        sideMargin,
        stringSpacing,
        fretSpacing,
        fingerPaint,
        openStringPaint,
        noStrumPaint,
        textPainter,
      );
    }
  }

  void _drawChordPositions(
    Canvas canvas,
    Size size,
    double topMargin,
    double sideMargin,
    double stringSpacing,
    double fretSpacing,
    Paint fingerPaint,
    Paint openStringPaint,
    Paint noStrumPaint,
    TextPainter textPainter,
  ) {
    final double fretboardHeight = size.height - topMargin - 40;

    // Draw finger positions for chords
    for (
      int stringIndex = 0;
      stringIndex < fretPositions.length && stringIndex < 6;
      stringIndex++
    ) {
      final fret = fretPositions[stringIndex];
      final x = sideMargin + (stringIndex * stringSpacing);

      if (fret > 0 && fret <= 6) {
        // Get the finger number for this position
        int fingerNum = -1;
        if (stringIndex < fingerPositions.length) {
          fingerNum = fingerPositions[stringIndex];
        }

        // Draw finger position (filled circle with color based on finger)
        final y = topMargin + ((fret - 0.5) * fretSpacing);

        // Use finger-specific color if available, otherwise default
        if (fingerNum > 0 && fingerNum <= 4) {
          fingerPaint.color = _getFingerColor(fingerNum);
        } else {
          fingerPaint.color = Color(0xFF368BF4); // Default blue
        }

        canvas.drawCircle(Offset(x, y), 14, fingerPaint);

        // Draw finger number on the circle (white text) instead of fret number
        String displayText = fingerNum > 0
            ? fingerNum.toString()
            : fret.toString();
        textPainter.text = TextSpan(
          text: displayText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      } else if (fret == 0) {
        // Open string - color the entire string in green
        canvas.drawLine(
          Offset(x, topMargin),
          Offset(x, topMargin + fretboardHeight),
          openStringPaint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0,
        );

        // // Original code: draw circle above the nut
        // canvas.drawCircle(Offset(x, topMargin - 15), 8, openStringPaint);
      }
    }

    // Mark strings that shouldn't be strummed - color the string in red
    for (String noStrumString in noStrumStrings) {
      int stringIndex = -1;

      // Map the no_strum string names to string indices
      if (noStrumString == 'E_low') {
        stringIndex = 0; // First E string (low E)
      } else if (noStrumString == 'A') {
        stringIndex = 1;
      } else if (noStrumString == 'D') {
        stringIndex = 2;
      } else if (noStrumString == 'G') {
        stringIndex = 3;
      } else if (noStrumString == 'B') {
        stringIndex = 4;
      } else if (noStrumString == 'E' || noStrumString == 'E_high') {
        stringIndex = 5; // High E string
      }

      if (stringIndex >= 0 && stringIndex < 6) {
        final x = sideMargin + (stringIndex * stringSpacing);

        // Color the entire string in red
        canvas.drawLine(
          Offset(x, topMargin),
          Offset(x, topMargin + fretboardHeight),
          noStrumPaint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0,
        );

        // // Original code: Draw X mark for no strum (above the nut)
        // final y = topMargin - 15;
        // canvas.drawLine(
        //   Offset(x - 6, y - 6),
        //   Offset(x + 6, y + 6),
        //   noStrumPaint,
        // );
        // canvas.drawLine(
        //   Offset(x + 6, y - 6),
        //   Offset(x - 6, y + 6),
        //   noStrumPaint,
        // );
      }
    }
  }

  void _drawScalePositions(
    Canvas canvas,
    Size size,
    double topMargin,
    double sideMargin,
    double stringSpacing,
    double fretSpacing,
  ) {
    final scalePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Draw scale positions
    for (
      int stringIndex = 0;
      stringIndex < scalePositions!.length && stringIndex < 6;
      stringIndex++
    ) {
      final positions = scalePositions![stringIndex];
      final x = sideMargin + (stringIndex * stringSpacing);

      for (int fret in positions) {
        if (fret > 0 && fret <= 6) {
          final y = topMargin + ((fret - 0.5) * fretSpacing);
          canvas.drawCircle(Offset(x, y), 8, scalePaint);
        } else if (fret == 0) {
          // Open string
          canvas.drawCircle(Offset(x, topMargin - 15), 8, scalePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant FretboardPainter oldDelegate) {
    // Only repaint if the actual data has changed
    return fretPositions != oldDelegate.fretPositions ||
        fingerPositions != oldDelegate.fingerPositions ||
        noStrumStrings != oldDelegate.noStrumStrings ||
        isScaleMode != oldDelegate.isScaleMode ||
        scalePositions != oldDelegate.scalePositions;
  }
}
