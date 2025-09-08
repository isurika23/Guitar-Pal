// Import required packages for Flutter UI and Bluetooth functionality
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  // Track Bluetooth connection status for UI indicator
  bool _connected = false;
  // Track if connection attempt is in progress
  bool _isConnecting = false;
  // Store connection status message
  String _connectionStatus = 'Disconnected';
  // Store the connected Bluetooth device
  BluetoothDevice? _connectedDevice;
  // Store the target Bluetooth characteristic for communication
  BluetoothCharacteristic? _targetCharacteristic;
  // Timer for periodic message sending to ESP32
  Timer? _sendTimer;

  // UUIDs for the ESP32 service and characteristic
  final String _serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String _characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  /// Initiates connection to ESP32 device via Bluetooth Low Energy (BLE)
  Future<void> _connectToESP32() async {
    // Update UI to show connecting state
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    // Check if Bluetooth adapter is on
    bool isBluetoothOn = await FlutterBluePlus.adapterState
        .firstWhere((state) => state == BluetoothAdapterState.on)
        .then((state) => true)
        .catchError((e) => false);
    if (!isBluetoothOn) {
      setState(() {
        _connectionStatus = 'Bluetooth is off';
        _connected = false;
        _isConnecting = false;
      });
      return;
    }

    // Start scanning for devices advertising the specified service UUID
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      withServices: [Guid(_serviceUUID)],
    );

    // Listen for scan results to find ESP32 device
    StreamSubscription<List<ScanResult>>? scanSubscription;
    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        // Check for device named 'ESP32_Isurika'
        if (result.device.platformName == 'ESP32_Isurika') {
          FlutterBluePlus.stopScan();
          _connectToDevice(result.device);
          scanSubscription?.cancel();
          return;
        }
      }
    });

    // Stop scanning after timeout if no device is found
    await Future.delayed(const Duration(seconds: 10));
    await FlutterBluePlus.stopScan();
    if (_connectedDevice == null) {
      setState(() {
        _connectionStatus = 'No ESP32 found';
        _connected = false;
        _isConnecting = false;
      });
    }
  }

  /// Connects to the specified Bluetooth device and discovers services
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      // Attempt to connect to the device
      await device.connect();
      setState(() {
        _connectedDevice = device;
        _connectionStatus = 'Connected';
        _connected = true;
        _isConnecting = false;
      });

      // Discover services offered by the device
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == _serviceUUID) {
          for (BluetoothCharacteristic char in service.characteristics) {
            if (char.uuid.toString() == _characteristicUUID) {
              _targetCharacteristic = char;
              _startSendingMessages();
              return;
            }
          }
        }
      }
      // Update status if characteristic is not found
      setState(() {
        _connectionStatus = 'Characteristic not found';
        _connected = false;
        _isConnecting = false;
      });
    } catch (e) {
      // Handle connection errors
      setState(() {
        _connectionStatus = 'Connection failed: $e';
        _connected = false;
        _isConnecting = false;
      });
    }
  }

  /// Periodically sends messages to the ESP32 device
  void _startSendingMessages() {
    _sendTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_targetCharacteristic != null) {
        try {
          // Send 'hello esp32' message to the characteristic
          await _targetCharacteristic!.write('hello esp32'.codeUnits);
        } catch (e) {
          // Handle write errors
          setState(() {
            _connectionStatus = 'Write failed: $e';
            _connected = false;
            _isConnecting = false;
          });
        }
      }
    });
  }

  /// Clean up resources when widget is disposed
  @override
  void dispose() {
    _sendTimer?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WillPopScope(
        // Handle Android back button behavior
        onWillPop: () async {
          if (_currentPage == AppPage.scalePractice ||
              _currentPage == AppPage.chordPractice) {
            // Return to Tutor page instead of closing app
            setState(() => _currentPage = AppPage.tutor);
            return false;
          }
          return true; // Allow app to close if at root
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
                        color: _connected
                            ? Colors.green[400]
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: (_connected || _isConnecting)
                              ? null
                              : _connectToESP32, // Disable during connection or when connected
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
                                _isConnecting
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
                                        color: _connected
                                            ? Colors.white
                                            : Colors.red,
                                      ),
                                SizedBox(width: 8),
                                // Display appropriate text based on state
                                Text(
                                  _isConnecting
                                      ? "Connecting..."
                                      : (_connected
                                            ? "Connected"
                                            : "Connect to Device"),
                                  style: TextStyle(
                                    color: _connected
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
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Tutor Placeholder"));
  }
}

/// ---------------- Scale Practice Page ----------------
class ScalePracticePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Scale Practice Page"));
  }
}

/// ---------------- Chord Practice Page ----------------
class ChordPracticePage extends StatefulWidget {
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
/// Displays guitar strings, frets, and finger positions
class FretboardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // String names (E A D G B E)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ["E", "A", "D", "G", "B", "E"]
              .map(
                (s) => Text(s, style: TextStyle(fontWeight: FontWeight.bold)),
              )
              .toList(),
        ),
        SizedBox(height: 10),

        // Fretboard grid (5 frets x 6 strings)
        Column(
          children: List.generate(5, (fret) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(6, (string) {
                // Fret 0: open/muted string indicators
                if (fret == 0) {
                  return Icon(Icons.circle, size: 16, color: Colors.grey);
                }
                // Example chord finger positions
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
