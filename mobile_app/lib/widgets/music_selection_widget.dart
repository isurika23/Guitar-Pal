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

        // Note selection chips
        Wrap(
          spacing: 6,
          children: notes.map((note) {
            return ChoiceChip(
              label: Text(note),
              selected: selectedNote == note,
              onSelected: (_) {
                int index = notes.indexOf(note);
                onNoteChanged(note, index);
              },
            );
          }).toList(),
        ),

        SizedBox(height: 20),

        // Type dropdown (Major/Minor)
        Row(
          children: [
            Text("Type: "),
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

        // Display option dropdown
        Row(
          children: [
            Text("Show: "),
            SizedBox(width: 10),
            DropdownButton<String>(
              value: showOption,
              items: [
                "Finger position",
                "Intervals",
                "Notes",
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                if (val != null) {
                  onShowOptionChanged(val);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
