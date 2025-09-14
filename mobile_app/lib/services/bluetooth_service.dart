import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ESP32BluetoothService {
  // Connection state tracking
  bool _connected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';
  BluetoothDevice? _connectedDevice;

  // Multiple characteristics for different purposes
  BluetoothCharacteristic? _initCharacteristic;
  BluetoothCharacteristic? _chordPixelCharacteristic;
  BluetoothCharacteristic? _scalePixelCharacteristic;

  Timer? _sendTimer;

  // UUIDs for the ESP32 service and characteristic
  final String _initServiceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String _initCharUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  final String _pixelServiceUUID = "c3c50c29-d4a5-4998-b382-62dcc1845e10";
  final String _chordPixelCharUUID = "c3c50c29-d4a5-4998-b382-62dcc1845e11";
  final String _scalePixelCharUUID = "c3c50c29-d4a5-4998-b382-62dcc1845e12";

  // Stream controllers for state updates
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _connectingStateController =
      StreamController<bool>.broadcast();
  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();

  // Getters for current state
  bool get connected => _connected;
  bool get isConnecting => _isConnecting;
  String get connectionStatus => _connectionStatus;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // Stream getters for listening to state changes
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<bool> get connectingStateStream => _connectingStateController.stream;
  Stream<String> get connectionStatusStream =>
      _connectionStatusController.stream;

  /// Initiates connection to ESP32 device via Bluetooth Low Energy (BLE)
  Future<void> connectToESP32() async {
    _updateConnectingState(true);
    _updateConnectionStatus('Connecting...');

    try {
      // Check if Bluetooth adapter is on
      var adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _updateConnectionStatus('Bluetooth is off');
        _updateConnectionState(false);
        _updateConnectingState(false);
        return;
      }

      // Start scanning for devices advertising the specified service UUID
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withServices: [Guid(_initServiceUUID)],
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
      scanSubscription?.cancel();
      if (_connectedDevice == null) {
        _updateConnectionStatus('No ESP32 found');
        _updateConnectionState(false);
        _updateConnectingState(false);
      }
    } catch (e) {
      _updateConnectionStatus('Error: $e');
      _updateConnectionState(false);
      _updateConnectingState(false);
    }
  }

  /// Connects to the specified Bluetooth device and discovers services
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      // Attempt to connect to the device
      await device.connect();
      _connectedDevice = device;
      _updateConnectionStatus('Connected');
      _updateConnectionState(true);
      _updateConnectingState(false);

      // Discover services offered by the device
      List<BluetoothService> services = await device.discoverServices();

      // Variables to track which characteristics we found
      bool foundInitChar = false;
      bool foundChordPixelChar = false;
      bool foundScalePixelChar = false;

      for (BluetoothService service in services) {
        // Check for initialization service
        if (service.uuid.toString().toLowerCase() ==
            _initServiceUUID.toLowerCase()) {
          for (BluetoothCharacteristic char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() ==
                _initCharUUID.toLowerCase()) {
              _initCharacteristic = char;
              foundInitChar = true;
              print('Found initialization characteristic');
            }
          }
        }
        // Check for pixel control service (for chord and scale display)
        else if (service.uuid.toString().toLowerCase() ==
            _pixelServiceUUID.toLowerCase()) {
          for (BluetoothCharacteristic char in service.characteristics) {
            // Chord pixel control characteristic
            if (char.uuid.toString().toLowerCase() ==
                _chordPixelCharUUID.toLowerCase()) {
              _chordPixelCharacteristic = char;
              foundChordPixelChar = true;
              print('Found chord pixel characteristic');
            }
            // Scale pixel control characteristic
            else if (char.uuid.toString().toLowerCase() ==
                _scalePixelCharUUID.toLowerCase()) {
              _scalePixelCharacteristic = char;
              foundScalePixelChar = true;
              print('Found scale pixel characteristic');
            }
          }
        }
      }

      // Start periodic messages if we found the init characteristic
      if (foundInitChar) {
        _startSendingMessages();
      }

      // Log which characteristics were found
      print(
        'Characteristics found - Init: $foundInitChar, Chord: $foundChordPixelChar, Scale: $foundScalePixelChar',
      );

      // Update status if no characteristics found
      if (!foundInitChar && !foundChordPixelChar && !foundScalePixelChar) {
        _updateConnectionStatus('No compatible characteristics found');
        _updateConnectionState(false);
        _updateConnectingState(false);
      }
    } catch (e) {
      // Handle connection errors
      _updateConnectionStatus('Connection failed: $e');
      _updateConnectionState(false);
      _updateConnectingState(false);
    }
  }

  /// Periodically sends messages to the ESP32 device using init characteristic
  void _startSendingMessages() {
    _sendTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_initCharacteristic != null && _connected) {
        try {
          // Send 'Guitar-Pal' message to the initialization characteristic
          await _initCharacteristic!.write('Guitar-Pal'.codeUnits);
          print('Sent periodic message to init characteristic');
        } catch (e) {
          // Handle write errors
          print('Init characteristic write failed: $e');
          _updateConnectionStatus('Write failed: $e');
          _updateConnectionState(false);
          _updateConnectingState(false);
        }
      }
    });
  }

  /// Send chord fret positions to ESP32 chord pixel characteristic
  Future<void> sendChordData(String fretPositions) async {
    if (_chordPixelCharacteristic != null && _connected) {
      try {
        // Send fret position data to chord pixel characteristic
        await _chordPixelCharacteristic!.write(fretPositions.codeUnits);
        print('Sent chord data to chord pixel characteristic: $fretPositions');
      } catch (e) {
        print('Chord characteristic write failed: $e');
        _updateConnectionStatus('Chord write failed: $e');
        // Note: Don't disconnect on write failure, just log the error
      }
    } else {
      print('Chord pixel characteristic not available or not connected');
      if (!_connected) {
        _updateConnectionStatus('Not connected to device');
      } else {
        _updateConnectionStatus('Chord characteristic not found');
      }
    }
  }

  /// Send scale data to ESP32 scale pixel characteristic
  Future<void> sendScaleData(String scaleData) async {
    if (_scalePixelCharacteristic != null && _connected) {
      try {
        // Send scale data to scale pixel characteristic
        await _scalePixelCharacteristic!.write(scaleData.codeUnits);
        print('Sent scale data to scale pixel characteristic: $scaleData');
      } catch (e) {
        print('Scale characteristic write failed: $e');
        _updateConnectionStatus('Scale write failed: $e');
        // Note: Don't disconnect on write failure, just log the error
      }
    } else {
      print('Scale pixel characteristic not available or not connected');
      if (!_connected) {
        _updateConnectionStatus('Not connected to device');
      } else {
        _updateConnectionStatus('Scale characteristic not found');
      }
    }
  }

  /// Send custom message to ESP32 (legacy method - uses init characteristic)
  Future<void> sendMessage(String message) async {
    if (_initCharacteristic != null && _connected) {
      try {
        await _initCharacteristic!.write(message.codeUnits);
        print('Sent message to init characteristic: $message');
      } catch (e) {
        print('Init characteristic write failed: $e');
        _updateConnectionStatus('Write failed: $e');
        _updateConnectionState(false);
        _updateConnectingState(false);
      }
    } else {
      print('Init characteristic not available or not connected');
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    _sendTimer?.cancel();
    _sendTimer = null;

    await _connectedDevice?.disconnect().catchError((e) {
      print('Error disconnecting: $e');
    });

    // Clear all characteristics
    _connectedDevice = null;
    _initCharacteristic = null;
    _chordPixelCharacteristic = null;
    _scalePixelCharacteristic = null;

    _updateConnectionState(false);
    _updateConnectionStatus('Disconnected');
    _updateConnectingState(false);
  }

  // Helper methods to update state and notify listeners
  void _updateConnectionState(bool connected) {
    _connected = connected;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(_connected);
    }
  }

  void _updateConnectingState(bool connecting) {
    _isConnecting = connecting;
    if (!_connectingStateController.isClosed) {
      _connectingStateController.add(_isConnecting);
    }
  }

  void _updateConnectionStatus(String status) {
    _connectionStatus = status;
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(_connectionStatus);
    }
  }

  /// Clean up resources
  void dispose() {
    _sendTimer?.cancel();
    _sendTimer = null;

    _connectedDevice?.disconnect().catchError((e) {
      print('Error disconnecting: $e');
    });

    // Clear all characteristics
    _connectedDevice = null;
    _initCharacteristic = null;
    _chordPixelCharacteristic = null;
    _scalePixelCharacteristic = null;

    if (!_connectionStateController.isClosed) {
      _connectionStateController.close();
    }
    if (!_connectingStateController.isClosed) {
      _connectingStateController.close();
    }
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.close();
    }
  }
}
