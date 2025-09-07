import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  bool _connected = false;

  final List<Widget> _pages = [
    HomePage(),
    TutorPage(),
    Center(child: Text("Tuner Page")),
    Center(child: Text("Profile Page")),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            // Top bar
            SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: _connected ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 6),
                          Text("Connect to Device"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Page content
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
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

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 20),
          Text(
            "Welcome Isurika!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(double.infinity, 80),
            ),
            onPressed: () {},
            child: Text(
              "Scale Practice",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: Size(double.infinity, 80),
            ),
            onPressed: () {
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
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(double.infinity, 80),
            ),
            onPressed: () {},
            child: Text(
              "Songs",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class TutorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Tutor Placeholder"));
  }
}

class ChordPracticePage extends StatefulWidget {
  @override
  _ChordPracticePageState createState() => _ChordPracticePageState();
}

class _ChordPracticePageState extends State<ChordPracticePage> {
  String selectedNote = "C";
  String chordType = "Major";
  String showOption = "Finger position";

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
            Text(
              "Select a Chord",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: notes.map((note) {
                return ChoiceChip(
                  label: Text(note),
                  selected: selectedNote == note,
                  onSelected: (_) {
                    setState(() {
                      selectedNote = note;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),
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
            Text(
              "$selectedNote $chordType",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text("C E G", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            FretboardWidget(),
          ],
        ),
      ),
    );
  }
}

class FretboardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // String names row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ["E", "A", "D", "G", "B", "E"]
              .map(
                (s) => Text(s, style: TextStyle(fontWeight: FontWeight.bold)),
              )
              .toList(),
        ),
        SizedBox(height: 10),
        // Example fretboard grid
        Column(
          children: List.generate(5, (fret) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(6, (string) {
                if (fret == 0) {
                  // open string / muted string
                  return Icon(Icons.circle, size: 16, color: Colors.grey);
                } else if (fret == 1 && string == 1) {
                  return Icon(Icons.circle, size: 20, color: Colors.red);
                } else if (fret == 2 && string == 2) {
                  return Icon(Icons.circle, size: 20, color: Colors.green);
                } else if (fret == 3 && string == 3) {
                  return Icon(Icons.circle, size: 20, color: Colors.blue);
                }
                return Container(width: 20, height: 20);
              }),
            );
          }),
        ),
      ],
    );
  }
}
