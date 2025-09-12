// Import required packages for Flutter UI and Bluetooth functionality
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'services/bluetooth_service.dart';

// Entry point of the application
void main() {
  runApp(MyApp());
}

/// Enum to track the current page in the app's navigation
enum AppPage { home, tutor, tuner, profile, scalePractice, chordPractice }

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Track the current page displayed
  AppPage _currentPage = AppPage.home;

  // Bluetooth service instance
  final ESP32BluetoothService _bluetoothService = ESP32BluetoothService();

  // Stream subscriptions for Bluetooth state updates
  late StreamSubscription<bool> _connectionStateSubscription;
  late StreamSubscription<bool> _connectingStateSubscription;
  late StreamSubscription<String> _connectionStatusSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to Bluetooth service state changes with error handling
    _connectionStateSubscription = _bluetoothService.connectionStateStream
        .listen(
          (connected) {
            if (mounted) setState(() {}); // Check if widget is still mounted
          },
          onError: (error) {
            print('Connection state stream error: $error');
          },
        );

    _connectingStateSubscription = _bluetoothService.connectingStateStream
        .listen(
          (connecting) {
            if (mounted) setState(() {}); // Check if widget is still mounted
          },
          onError: (error) {
            print('Connecting state stream error: $error');
          },
        );

    _connectionStatusSubscription = _bluetoothService.connectionStatusStream
        .listen(
          (status) {
            if (mounted) setState(() {}); // Check if widget is still mounted
          },
          onError: (error) {
            print('Connection status stream error: $error');
          },
        );
  }

  /// Clean up resources when widget is disposed
  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _connectingStateSubscription.cancel();
    _connectionStatusSubscription.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            if (_currentPage == AppPage.scalePractice ||
                _currentPage == AppPage.chordPractice) {
              // Return to Tutor page instead of closing app
              setState(() => _currentPage = AppPage.tutor);
            } else {
              // Exit the app
              SystemNavigator.pop();
            }
          }
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
                      // Connect button with dynamic appearance
                      Material(
                        color: _bluetoothService.connected
                            ? Colors.green[400]
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap:
                              (_bluetoothService.connected ||
                                  _bluetoothService.isConnecting)
                              ? null
                              : _bluetoothService
                                    .connectToESP32, // Disable during connection or when connected
                          hoverColor: Colors.grey[400],
                          splashColor: Colors.greenAccent,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Show loading animation or status circle
                                _bluetoothService.isConnecting
                                    ? SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Icon(
                                        Icons.circle,
                                        size: 12,
                                        color: _bluetoothService.connected
                                            ? Colors.white
                                            : Colors.red,
                                      ),
                                SizedBox(width: 8),
                                // Display appropriate text based on state
                                Text(
                                  _bluetoothService.isConnecting
                                      ? "Connecting..."
                                      : (_bluetoothService.connected
                                            ? "Connected"
                                            : "Connect to Device"),
                                  style: TextStyle(
                                    color: _bluetoothService.connected
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  /// Returns the appropriate widget based on the current page
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
        return TutorPage(
          onScalePressed: () {
            setState(() => _currentPage = AppPage.scalePractice);
          },
          onChordPressed: () {
            setState(() => _currentPage = AppPage.chordPractice);
          },
        );
      case AppPage.tuner:
        return Center(child: Text("Tuner Page"));
      case AppPage.profile:
        return Center(child: Text("Profile Page"));
      case AppPage.scalePractice:
        return ScalePracticePage();
      case AppPage.chordPractice:
        return ChordPracticePage(bluetoothService: _bluetoothService);
    }
  }

  /// Maps navigation bar index to AppPage
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

  /// Maps AppPage to navigation bar index
  /// Tutor is selected for both ScalePractice and ChordPractice
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
            // App logo
            Image.asset("assets/images/logo-2287665_1280.png", height: 120),
            Text(
              "Welcome Isurika!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Scale Practice button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 80),
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

            // Chord Practice button
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

            // Songs button (placeholder)
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
  final VoidCallback onScalePressed;
  final VoidCallback onChordPressed;

  const TutorPage({
    required this.onScalePressed,
    required this.onChordPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Tutor Page",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text("Choose your practice mode:"),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: onScalePressed,
            child: Text("Scale Practice"),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: onChordPressed,
            child: Text("Chord Practice"),
          ),
        ],
      ),
    );
  }
}

/// ---------------- Scale Practice Page ----------------
class ScalePracticePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Scale Practice",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text("Practice your scales here"),
          // Add scale practice functionality
        ],
      ),
    );
  }
}

/// ---------------- Chord Practice Page ----------------
class ChordPracticePage extends StatefulWidget {
  final ESP32BluetoothService bluetoothService;

  const ChordPracticePage({required this.bluetoothService, Key? key})
    : super(key: key);

  @override
  _ChordPracticePageState createState() => _ChordPracticePageState();
}

class _ChordPracticePageState extends State<ChordPracticePage> {
  // State variables for chord selection
  String selectedNote = "C";
  String chordType = "Major";
  String showOption = "Finger position";

  // List of musical notes for selection
  List<String> notes = [
    "C",
    "C#",
    "D♭",
    "D",
    "D#",
    "E♭",
    "E",
    "F",
    "F#",
    "G♭",
    "G",
    "G#",
    "A♭",
    "A",
    "A#",
    "B♭",
    "B",
  ];

  // Send chord information to ESP32 when selection changes
  void _sendChordToESP32() {
    String chordInfo = "$selectedNote$chordType";
    widget.bluetoothService.sendMessage(chordInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chord selection title
            Text(
              "Select a Chord",
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
                    setState(() {
                      selectedNote = note;
                    });
                    _sendChordToESP32();
                  },
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            // Chord type dropdown
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
                    _sendChordToESP32();
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

            // Display selected chord and notes
            Text(
              "$selectedNote $chordType",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text("C E G", style: TextStyle(fontSize: 18)),

            SizedBox(height: 20),

            // Fretboard display
            FretboardWidget(),
          ],
        ),
      ),
    );
  }
}

/// ---------------- Fretboard Widget ----------------
class FretboardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.brown),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          "Fretboard Display\n(To be implemented)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
