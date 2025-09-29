import 'package:flutter/material.dart';

/// A reusable fretboard widget that displays finger positions for chords and scales
class FretboardWidget extends StatelessWidget {
  final List<int> fretPositions;
  final List<String> noStrumStrings;
  final String title;
  final bool isScaleMode;
  final List<List<int>>? scalePositions;
  final String selectedNote;
  final String selectedType;
  final List<String> notes;

  const FretboardWidget({
    required this.fretPositions,
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
          // Chord/Scale name
          Text(
            "$selectedNote $selectedType",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          
          // Notes display
          Text(
            notes.join(" "),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 20),
          
          // Fretboard visualization
          _buildFretboard(),
        ],
      ),
    );
  }

  Widget _buildFretboard() {
    return Container(
      height: 300,
      width: double.infinity,
      child: CustomPaint(
        painter: FretboardPainter(
          fretPositions: fretPositions,
          noStrumStrings: noStrumStrings,
          isScaleMode: isScaleMode,
          scalePositions: scalePositions,
        ),
      ),
    );
  }
}

/// Custom painter for drawing the fretboard
class FretboardPainter extends CustomPainter {
  final List<int> fretPositions;
  final List<String> noStrumStrings;
  final bool isScaleMode;
  final List<List<int>>? scalePositions;

  FretboardPainter({
    required this.fretPositions,
    required this.noStrumStrings,
    this.isScaleMode = false,
    this.scalePositions,
  });

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
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final openStringPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final noStrumPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0;

    // Guitar string names (from low E to high e)
    final stringNames = ['E', 'A', 'D', 'G', 'B', 'E'];
    
    // Constants for fretboard layout
    const int numStrings = 6;
    const int numFrets = 5;
    final double topMargin = 60; // Increased to accommodate string names at top
    final double bottomMargin = 30;
    final double sideMargin = 60;
    
    final double fretboardHeight = size.height - topMargin - bottomMargin;
    final double fretboardWidth = size.width - (sideMargin * 2);
    final double stringSpacing = fretboardHeight / (numStrings - 1);
    final double fretSpacing = fretboardWidth / numFrets;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw string names at the TOP of each string (above the fretboard)
    for (int i = 0; i < numStrings; i++) {
      final y = topMargin + (i * stringSpacing);
      
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
        Offset(20, y - textPainter.height - 10), // Above the string line
      );
    }

    // Draw strings (horizontal lines)
    for (int i = 0; i < numStrings; i++) {
      final y = topMargin + (i * stringSpacing);
      canvas.drawLine(
        Offset(sideMargin, y),
        Offset(sideMargin + fretboardWidth, y),
        stringPaint,
      );
    }

    // Draw nut (thick line at the beginning)
    canvas.drawLine(
      Offset(sideMargin, topMargin),
      Offset(sideMargin, topMargin + fretboardHeight),
      nutPaint,
    );

    // Draw frets (vertical lines)
    for (int i = 1; i <= numFrets; i++) {
      final x = sideMargin + (i * fretSpacing);
      canvas.drawLine(
        Offset(x, topMargin),
        Offset(x, topMargin + fretboardHeight),
        fretPaint,
      );
    }

    // Draw fret numbers below the fretboard
    for (int i = 1; i <= numFrets; i++) {
      final x = sideMargin + ((i - 0.5) * fretSpacing);
      textPainter.text = TextSpan(
        text: i.toString(),
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 20),
      );
    }

    if (isScaleMode && scalePositions != null) {
      _drawScalePositions(canvas, size, topMargin, sideMargin, stringSpacing, fretSpacing);
    } else {
      _drawChordPositions(canvas, size, topMargin, sideMargin, stringSpacing, fretSpacing, 
                         fingerPaint, openStringPaint, noStrumPaint, textPainter);
    }
  }

  void _drawChordPositions(Canvas canvas, Size size, double topMargin, double sideMargin,
                          double stringSpacing, double fretSpacing, Paint fingerPaint, 
                          Paint openStringPaint, Paint noStrumPaint, TextPainter textPainter) {
    
    // Draw finger positions for chords
    for (int stringIndex = 0; stringIndex < fretPositions.length && stringIndex < 6; stringIndex++) {
      final fret = fretPositions[stringIndex];
      final y = topMargin + (stringIndex * stringSpacing);

      if (fret > 0 && fret <= 5) {
        // Draw finger position (filled circle)
        final x = sideMargin + ((fret - 0.5) * fretSpacing);
        canvas.drawCircle(
          Offset(x, y),
          12,
          fingerPaint,
        );
        
        // Draw fret number on the circle (white text)
        textPainter.text = TextSpan(
          text: fret.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      } else if (fret == 0) {
        // Open string - draw circle at the nut
        canvas.drawCircle(
          Offset(sideMargin - 15, y),
          8,
          openStringPaint,
        );
      }
    }

    // Mark strings that shouldn't be strummed
    final stringNames = ['E', 'A', 'D', 'G', 'B', 'E'];
    for (String noStrumString in noStrumStrings) {
      int stringIndex = stringNames.indexOf(noStrumString);
      if (stringIndex >= 0 && stringIndex < 6) {
        final y = topMargin + (stringIndex * stringSpacing);
        // Draw X mark for no strum (at the nut area)
        final x = sideMargin - 15;
        canvas.drawLine(
          Offset(x - 6, y - 6),
          Offset(x + 6, y + 6),
          noStrumPaint,
        );
        canvas.drawLine(
          Offset(x + 6, y - 6),
          Offset(x - 6, y + 6),
          noStrumPaint,
        );
      }
    }
  }

  void _drawScalePositions(Canvas canvas, Size size, double topMargin, double sideMargin,
                          double stringSpacing, double fretSpacing) {
    final scalePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Draw scale positions
    for (int stringIndex = 0; stringIndex < scalePositions!.length && stringIndex < 6; stringIndex++) {
      final positions = scalePositions![stringIndex];
      final y = topMargin + (stringIndex * stringSpacing);

      for (int fret in positions) {
        if (fret > 0 && fret <= 5) {
          final x = sideMargin + ((fret - 0.5) * fretSpacing);
          canvas.drawCircle(
            Offset(x, y),
            8,
            scalePaint,
          );
        } else if (fret == 0) {
          // Open string
          canvas.drawCircle(
            Offset(sideMargin - 15, y),
            8,
            scalePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}