// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 BLE Connector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  String connectionStatus = 'Disconnected';
  Timer? _sendTimer;

  final String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  Future<void> _connectToESP32() async {
    // Check if Bluetooth is on
    bool isBluetoothOn = await FlutterBluePlus.adapterState
        .firstWhere((state) => state == BluetoothAdapterState.on)
        .then((state) => true)
        .catchError((e) => false);
    if (!isBluetoothOn) {
      setState(() {
        connectionStatus = 'Bluetooth is off';
      });
      return;
    }

    // Start scanning for devices advertising the service UUID
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      withServices: [Guid(serviceUUID)],
    );

    // Listen for scan results
    StreamSubscription<List<ScanResult>>? scanSubscription;
    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.platformName == 'ESP32_Isurika') { // Use platformName
          FlutterBluePlus.stopScan();
          _connectToDevice(result.device);
          scanSubscription?.cancel();
          return;
        }
      }
    });

    // Stop scanning after timeout if no device found
    await Future.delayed(const Duration(seconds: 10));
    await FlutterBluePlus.stopScan();
    if (connectedDevice == null) {
      setState(() {
        connectionStatus = 'No ESP32 found';
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
        connectionStatus = 'Connected';
      });

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == serviceUUID) {
          for (BluetoothCharacteristic char in service.characteristics) {
            if (char.uuid.toString() == characteristicUUID) {
              targetCharacteristic = char;
              _startSendingMessages();
              return;
            }
          }
        }
      }
      setState(() {
        connectionStatus = 'Characteristic not found';
      });
    } catch (e) {
      setState(() {
        connectionStatus = 'Connection failed: $e';
      });
    }
  }

  void _startSendingMessages() {
    _sendTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (targetCharacteristic != null) {
        try {
          await targetCharacteristic!.write('hello esp32'.codeUnits);
        } catch (e) {
          setState(() {
            connectionStatus = 'Write failed: $e';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 BLE Connector'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Status: $connectionStatus'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: connectionStatus == 'Connected' ? null : _connectToESP32,
              child: const Text('Connect to ESP32'),
            ),
          ],
        ),
      ),
    );
  }
}