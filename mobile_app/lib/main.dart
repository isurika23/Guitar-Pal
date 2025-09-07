import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

/// Root widget of the app
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0; // keeps track of which bottom nav tab is selected
  bool _connected = false; // connection status (controls the top dot color)

  // List of pages for bottom navigation
  final List<Widget> _pages = [
    HomePage(), // Page 0
    ChordPracticePage(), // Page 1
    Center(child: Text("Tuner Page")), // Page 2
    Center(child: Text("Profile Page")), // Page 3
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            // ------------------ Top bar with "Connect to Device" ------------------
            SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300], // light background
                        borderRadius: BorderRadius.circular(20), // rounded pill
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Row(
                        children: [
                          // Circle changes color depending on _connected
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: _connected ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 6),
                          Text(_connected ? "Connected" : "Connect to Device"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ------------------ Page content (scrollable middle part) ------------------
            Expanded(child: _pages[_currentIndex]),
          ],
        ),

        // ------------------ Bottom navigation bar ------------------
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              // print('Selected index: $index');
              _currentIndex = index; // switch tab
            });
          },
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.black,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.school), label: "Tutor"),
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note),
              label: "Tuner",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

/// ------------------ Home Page ------------------
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            // Image at the top
            Image.asset("assets/images/logo-2287665_1280.png", height: 120),
            // SizedBox(height: 20),
            Text(
              "Welcome Isurika!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Scale Practice button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 80), // full width
              ),
              onPressed: () {},
              child: Text(
                "Scale Practice",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(234, 255, 255, 255),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Chords Practice button (navigates to chord page)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: Size(double.infinity, 80),
              ),
              onPressed: () {
                // navigate to chord practice page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChordPracticePage()),
                );
              },
              child: Text(
                "Chords Practice",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(234, 255, 255, 255),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Songs button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 80),
              ),
              onPressed: () {},
              child: Text(
                "Songs",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(234, 255, 255, 255),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------ Tutor Page Placeholder ------------------
class TutorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Tutor Placeholder"));
  }
}

/// ------------------ Chord Practice Page ------------------
class ChordPracticePage extends StatefulWidget {
  @override
  _ChordPracticePageState createState() => _ChordPracticePageState();
}

class _ChordPracticePageState extends State<ChordPracticePage> {
  String selectedNote = "C"; // currently selected note
  String chordType = "Major"; // selected chord type
  String showOption = "Finger position"; // selected display option

  // List of note buttons
  List<String> notes = [
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Select a Chord",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // ------------------ Note selection chips ------------------
            Wrap(
              spacing: 6,
              children: notes.map((note) {
                return ChoiceChip(
                  label: Text(note),
                  selected: selectedNote == note, // highlight when selected
                  onSelected: (_) {
                    setState(() {
                      selectedNote = note; // update selected note
                    });
                  },
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            // ------------------ Chord type dropdown ------------------
            Row(
              children: [
                Text("Type: "),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: chordType,
                  items: ["Major", "Minor"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      chordType = val!;
                    });
                  },
                ),
              ],
            ),

            // ------------------ Show option dropdown ------------------
            Row(
              children: [
                Text("Show: "),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: showOption,
                  items: ["Finger position", "Intervals", "Notes"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      showOption = val!;
                    });
                  },
                ),
              ],
            ),

            SizedBox(height: 20),

            // ------------------ Chord name + notes ------------------
            Text(
              "$selectedNote $chordType", // e.g. "C Major"
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text("C E G", style: TextStyle(fontSize: 18)), // chord notes list

            SizedBox(height: 20),

            // ------------------ Fretboard ------------------
            FretboardWidget(),
          ],
        ),
      ),
    );
  }
}

/// ------------------ Fretboard Widget ------------------
/// Displays strings, frets, and finger positions
class FretboardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // String names row (E A D G B E)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ["E", "A", "D", "G", "B", "E"]
              .map(
                (s) => Text(s, style: TextStyle(fontWeight: FontWeight.bold)),
              )
              .toList(),
        ),
        SizedBox(height: 10),

        // Example fretboard grid (5 frets x 6 strings)
        Column(
          children: List.generate(5, (fret) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(6, (string) {
                // Fret 0 = open/muted string indicators
                if (fret == 0) {
                  return Icon(Icons.circle, size: 16, color: Colors.grey);
                }
                // Example chord finger positions:
                else if (fret == 1 && string == 1) {
                  return Icon(Icons.circle, size: 20, color: Colors.red);
                } else if (fret == 2 && string == 2) {
                  return Icon(Icons.circle, size: 20, color: Colors.green);
                } else if (fret == 3 && string == 3) {
                  return Icon(Icons.circle, size: 20, color: Colors.blue);
                }
                // Empty fret
                return Container(width: 20, height: 20);
              }),
            );
          }),
        ),
      ],
    );
  }
}
