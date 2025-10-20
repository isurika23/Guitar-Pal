import 'package:flutter/material.dart';

/// Reusable music selection widget for both chords and scales
class MusicSelectionWidget extends StatelessWidget {
  final String title;
  final String? selectedNote;
  final String selectedType;
  final String showOption;
  final List<String> notes;
  final List<String> types;
  final Function(String note, int index) onNoteChanged;
  final Function(String type) onTypeChanged;
  final Function(String option) onShowOptionChanged;

  const MusicSelectionWidget({
    required this.title,
    required this.selectedNote,
    required this.selectedType,
    required this.showOption,
    required this.notes,
    required this.types,
    required this.onNoteChanged,
    required this.onTypeChanged,
    required this.onShowOptionChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),

        // Note selection buttons in a structured grid
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6, // 6 notes per row (2 rows for 12 notes)
            childAspectRatio: 2, // Width to height ratio
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final isSelected = selectedNote == note;

            return ElevatedButton(
              onPressed: () {
                onNoteChanged(note, index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                foregroundColor: isSelected ? Colors.white : Colors.black87,
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                note,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          },
        ),

        SizedBox(height: 20),

        // Type dropdown (Major/Minor)
        Row(
          children: [
            Text(
              "Type: ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 10),
            DropdownButton<String>(
              value: selectedType,
              items: types
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  onTypeChanged(val);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
