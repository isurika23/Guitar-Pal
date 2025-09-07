import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

/// AppPage enum to track which page is showing
enum AppPage { home, tutor, tuner, profile, scalePractice, chordPractice }

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppPage _currentPage = AppPage.home;
  bool _connected = false; // state for connect button circle

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WillPopScope(
        // Handle Android back button
        onWillPop: () async {
          if (_currentPage == AppPage.scalePractice ||
              _currentPage == AppPage.chordPractice) {
            // If in a practice page → go back to Tutor instead of closing app
            setState(() => _currentPage = AppPage.tutor);
            return false;
          }
          return true; // default behavior (exit app if at root)
        },
        child: Scaffold(
          body: Column(
            children: [
              // ---------------- top bar ----------------
              SafeArea(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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

              // ---------------- main content ----------------
              Expanded(child: _buildPage()),
            ],
          ),

          // ---------------- bottom navigation ----------------
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _navIndexForPage(_currentPage),
            onTap: (index) {
              setState(() {
                _currentPage = _pageForNavIndex(index);
              });
            },
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.school), label: "Tutor"),
              BottomNavigationBarItem(
                icon: Icon(Icons.music_note),
                label: "Tuner",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Map current page → visible widget
  Widget _buildPage() {
    switch (_currentPage) {
      case AppPage.home:
        return HomePage(
          onScalePressed: () {
            setState(() => _currentPage = AppPage.scalePractice);
          },
          onChordPressed: () {
            setState(() => _currentPage = AppPage.chordPractice);
          },
        );
      case AppPage.tutor:
        return TutorPage();
      case AppPage.tuner:
        return Center(child: Text("Tuner Page"));
      case AppPage.profile:
        return Center(child: Text("Profile Page"));
      case AppPage.scalePractice:
        return ScalePracticePage();
      case AppPage.chordPractice:
        return ChordPracticePage();
    }
  }

  /// Map nav index → AppPage
  AppPage _pageForNavIndex(int index) {
    switch (index) {
      case 0:
        return AppPage.home;
      case 1:
        return AppPage.tutor;
      case 2:
        return AppPage.tuner;
      case 3:
        return AppPage.profile;
      default:
        return AppPage.home;
    }
  }

  /// Map AppPage → nav index
  /// (Tutor is selected for both ScalePractice & ChordPractice)
  int _navIndexForPage(AppPage page) {
    switch (page) {
      case AppPage.home:
        return 0;
      case AppPage.tutor:
      case AppPage.scalePractice:
      case AppPage.chordPractice:
        return 1;
      case AppPage.tuner:
        return 2;
      case AppPage.profile:
        return 3;
    }
  }
}

/// ---------------- Home Page ----------------
class HomePage extends StatelessWidget {
  final VoidCallback onScalePressed;
  final VoidCallback onChordPressed;

  const HomePage({
    required this.onScalePressed,
    required this.onChordPressed,
    Key? key,
  }) : super(key: key);

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
              onPressed: onScalePressed,
              child: Text(
                "Scale Practice",
                style: TextStyle(
                  color: const Color.fromARGB(234, 255, 255, 255),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
              onPressed: onChordPressed,
              child: Text(
                "Chord Practice",
                style: TextStyle(
                  color: const Color.fromARGB(234, 255, 255, 255),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Songs placeholder
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

/// ---------------- Tutor Page ----------------
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

/// ---------------- Scale Practice Page ----------------
class ScalePracticePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Scale Practice Page"));
  }
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
