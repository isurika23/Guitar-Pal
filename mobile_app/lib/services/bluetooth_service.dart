import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ESP32BluetoothService {
  // Connection state tracking
  bool _connected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _targetCharacteristic;
  Timer? _sendTimer;

  // UUIDs for the ESP32 service and characteristic
  final String _serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String _characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // Stream controllers for state updates
  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  final StreamController<bool> _connectingStateController = StreamController<bool>.broadcast();
  final StreamController<String> _connectionStatusController = StreamController<String>.broadcast();

  // Getters for current state
  bool get connected => _connected;
  bool get isConnecting => _isConnecting;
  String get connectionStatus => _connectionStatus;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // Stream getters for listening to state changes
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<bool> get connectingStateStream => _connectingStateController.stream;
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;

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
      for (BluetoothService service in services) {
        // Compare UUIDs properly (case insensitive)
        if (service.uuid.toString().toLowerCase() == _serviceUUID.toLowerCase()) {
          for (BluetoothCharacteristic char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == _characteristicUUID.toLowerCase()) {
              _targetCharacteristic = char;
              _startSendingMessages();
              return;
            }
          }
        }
      }
      // Update status if characteristic is not found
      _updateConnectionStatus('Characteristic not found');
      _updateConnectionState(false);
      _updateConnectingState(false);
    } catch (e) {
      // Handle connection errors
      _updateConnectionStatus('Connection failed: $e');
      _updateConnectionState(false);
      _updateConnectingState(false);
    }
  }

  /// Periodically sends messages to the ESP32 device
  void _startSendingMessages() {
    _sendTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_targetCharacteristic != null && _connected) {
        try {
          // Send 'Major' message to the characteristic
          await _targetCharacteristic!.write('Major'.codeUnits);
        } catch (e) {
          // Handle write errors
          _updateConnectionStatus('Write failed: $e');
          _updateConnectionState(false);
          _updateConnectingState(false);
        }
      }
    });
  }

  /// Send custom message to ESP32
  Future<void> sendMessage(String message) async {
    if (_targetCharacteristic != null && _connected) {
      try {
        await _targetCharacteristic!.write(message.codeUnits);
      } catch (e) {
        _updateConnectionStatus('Write failed: $e');
        _updateConnectionState(false);
        _updateConnectingState(false);
      }
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    _sendTimer?.cancel();
    _sendTimer = null;
    
    await _connectedDevice?.disconnect().catchError((e) {
      print('Error disconnecting: $e');
    });
    _connectedDevice = null;
    _targetCharacteristic = null;
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
    _connectedDevice = null;
    _targetCharacteristic = null;
    
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