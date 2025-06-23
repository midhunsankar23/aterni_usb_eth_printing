# Aterni USB/Ethernet Printing - Usage Guide

This guide explains how to integrate USB printer functionality into your Flutter application using the `aterni_usb_eth_printing` package.

## Table of Contents
- [Installation](#installation)
- [Automatic Printer Detection](#automatic-printer-detection)
- [Basic Usage](#basic-usage)
- [Advanced Usage](#advanced-usage)
- [Error Handling](#error-handling)
- [Platform-Specific Information](#platform-specific-information)
- [Troubleshooting](#troubleshooting)

## Installation

1. Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  aterni_usb_eth_printing: ^x.x.x  # Replace with the latest version
```

2. Import the package in your code:

```dart
import 'package:aterni_usb_eth_printing/aterni_usb_eth_printing.dart';
```

## Automatic Printer Detection

To automatically detect printers when your app starts:

### 1. Create an instance of the printer class

```dart
final AterniUsbEthPrinting _printer = AterniUsbEthPrinting();
```

### 2. Set up lifecycle observation to handle app state changes

Implement `WidgetsBindingObserver` to detect when the app comes to the foreground:

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  List<Map<String, dynamic>> devices = [];
  final AterniUsbEthPrinting _printer = AterniUsbEthPrinting();
  bool connected = false;
  bool _isLoading = false;
  String _statusMessage = '';
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Delay a bit to ensure app initialization is complete
    Future.delayed(const Duration(milliseconds: 500), () {
      _getDevicelist();
      
      // Optional: Set up periodic scanning
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!connected) {
          _getDevicelist(silentMode: true);
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - refresh devices
      _getDevicelist();
    }
  }
}
```

### 3. Implement the device discovery method

```dart
Future<void> _getDevicelist({bool silentMode = false}) async {
  if (_isLoading) return; // Prevent multiple concurrent requests
  
  if (!silentMode) {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Searching for USB printers...';
    });
  }
  
  List<Map<String, dynamic>> results = [];
  try {
    results = await _printer.getUSBDeviceList();
    print("Found devices: ${results.length}");
    
    setState(() {
      devices = results;
      _isLoading = false;
      _statusMessage = results.isEmpty ? 'No USB printers found' : '';
    });
    
    // Auto connect to the first printer if available
    if (results.isNotEmpty && !connected) {
      _tryAutoConnect(results.first);
    }
  } on PlatformException catch (e) {
    print("Error getting device list: ${e.message}");
    if (!silentMode) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.message}';
      });
    }
  }
}

Future<void> _tryAutoConnect(Map<String, dynamic> device) async {
  try {
    print("Attempting auto-connect to ${device['manufacturer']} ${device['productName']}");
    await _connect(
      int.parse(device['vendorId']),
      int.parse(device['productId']),
    );
  } catch (e) {
    print("Auto-connect failed: $e");
  }
}
```

## Basic Usage

### Connect to a USB Printer

```dart
Future<void> _connect(int vendorId, int productId) async {
  setState(() {
    _statusMessage = 'Connecting to printer...';
    _isLoading = true;
  });
  
  try {
    final bool? result = await _printer.connect(vendorId, productId);
    
    setState(() {
      _isLoading = false;
      
      if (result == true) {
        connected = true;
        _statusMessage = 'Connected to printer. Ready to print.';
      } else {
        _statusMessage = 'Failed to connect. Please check printer and permissions.';
      }
    });
  } on PlatformException catch (e) {
    print("Error connecting to device: ${e.message}");
    setState(() {
      _isLoading = false;
      _statusMessage = 'Error: ${e.message}';
    });
  }
}
```

### Print Plain Text

```dart
Future<void> printText(String text) async {
  try {
    var data = Uint8List.fromList(utf8.encode(text));
    await _printer.write(data);
  } on PlatformException catch (e) {
    print("Error printing: ${e.message}");
  }
}
```

### Close Connection

```dart
Future<void> closeConnection() async {
  try {
    await _printer.close();
  } on PlatformException catch (e) {
    print("Error closing connection: ${e.message}");
  }
}
```

## Advanced Usage

### Formatted Printing with ESC/POS Commands

```dart
Future<void> printFormattedText() async {
  List<int> bytes = [];
  
  // Center align
  bytes.addAll([0x1B, 0x61, 0x01]);
  
  // Bold text
  bytes.addAll([0x1B, 0x45, 0x01]);
  bytes.addAll(utf8.encode('Bold Centered Text\n'));
  
  // Cancel bold
  bytes.addAll([0x1B, 0x45, 0x00]);
  
  // Left align
  bytes.addAll([0x1B, 0x61, 0x00]);
  bytes.addAll(utf8.encode('Normal Left Text\n'));
  
  // Feed and cut
  bytes.addAll([0x1D, 0x56, 0x41, 0x03]);

  await _printer.write(Uint8List.fromList(bytes));
}
```

### Print Image

To print an image, convert it to ESC/POS printer command format:

```dart
Future<void> printImage(Uint8List imageBytes) async {
  // This is a simplified example. In a real application, you would need 
  // to convert the image to printer-specific commands.
  
  List<int> bytes = [];
  // Add image processing commands here
  
  await _printer.write(Uint8List.fromList(bytes));
}
```

## Error Handling

Implement comprehensive error handling to manage permission issues and connection problems:

```dart
try {
  // Printer operation
} on PlatformException catch (e) {
  if (e.code == 'PERMISSION_DENIED') {
    // Handle permission issues
  } else if (e.code == 'DEVICE_NOT_FOUND') {
    // Handle missing device
  } else if (e.code == 'CONNECTION_ERROR') {
    // Handle connection problems
  } else {
    // Handle other errors
  }
}
```

## Platform-Specific Information

### Android

For Android, ensure your AndroidManifest.xml includes:

```xml
<uses-feature android:name="android.hardware.usb.host" android:required="true" />
<uses-permission android:name="android.permission.USB_PERMISSION" />
```

### iOS

USB printing is not supported on iOS due to platform limitations. Use Bluetooth or network printing instead.

## Troubleshooting

### Common Issues and Solutions

1. **Printer not detected**
   - Ensure USB OTG is supported and enabled on your device
   - Verify that your printer is powered on and properly connected
   - Try reconnecting the USB cable

2. **Permission denied**
   - Make sure you've included the proper permissions in AndroidManifest.xml
   - Check that the user has accepted the permission dialog
   - For Android 10+ devices, verify USB device access permissions

3. **Printing fails**
   - Verify that the printer is properly connected and has paper
   - Check if the print data format is compatible with your printer model
   - Try sending smaller chunks of data

4. **Garbled text output**
   - Ensure you're using the correct character encoding for your printer
   - Check printer codepage settings
   - Try using printer manufacturer's recommended commands

---

This guide covers the most common usage scenarios. For more specific needs or advanced configurations, please refer to the project's main README or open an issue on the GitHub repository.
