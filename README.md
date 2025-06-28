# aterni_usb_eth_printing

A Flutter plugin for USB and Ethernet printer support. Supports both USB printing on Android and Network (Ethernet/WiFi) printing with ESC/POS commands.

## Features

### USB Printing
* Discover USB printers on Android
* Connect to USB printers with permission handling
* Print raw data and formatted text using ESC/POS commands
* Support for common printer commands (text formatting, alignment, paper cut, etc.)

### Network Printing
* Connect to network printers via IP address
* Full ESC/POS command support
* Print text, images, QR codes, barcodes
* Receipt formatting with tables and styles
* Compatible with most ESC/POS network printers

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  aterni_usb_eth_printing:
    git:
      url: https://github.com/your-username/aterni_usb_eth_printing.git
```

### Android Setup (for USB printing)

Add USB permissions to your Android Manifest (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-feature android:name="android.hardware.usb.host" />
<uses-permission android:name="android.permission.USB_PERMISSION" />
```

## Usage

### USB Printing

```dart
import 'package:aterni_usb_eth_printing/aterni_usb_eth_printing.dart';

// Create printer instance
final printer = AterniUsbEthPrinting();

// Get available USB devices
final devices = await printer.getUSBDeviceList();

// Connect to a printer
final connected = await printer.connect(vendorId, productId);

// Print text
final data = Uint8List.fromList(utf8.encode('Hello World\n'));
await printer.write(data);
```

### Network Printing

```dart
import 'package:aterni_usb_eth_printing/aterni_usb_eth_printing.dart';
// All classes including PaperSize, CapabilityProfile, PosStyles are exported

// Create network printer instance
final profile = await CapabilityProfile.load();
final printer = NetworkPrinter(PaperSize.mm80, profile);

// Connect to network printer
final result = await printer.connect('192.168.1.100', port: 9100);

if (result == PosPrintResult.success) {
  // Print formatted text
  printer.text('Hello World!', styles: PosStyles(bold: true));
  
  // Print QR code
  printer.qrcode('https://example.com');
  
  // Cut paper
  printer.cut();
}

// Disconnect
printer.disconnect();
```

## Documentation

- **[USB Printing Usage Guide](USAGE.md)** - Complete guide for USB printing
- **[Network Printing Usage Guide](NETWORK_PRINTER_USAGE.md)** - Complete guide for network printing
- **[Quick Integration Guide](QUICK_INTEGRATION.md)** - Step-by-step integration
- **[Enum and Class Reference](ENUM_REFERENCE.md)** - Complete reference for all available enums and classes
- **[Example Projects](example/)** - Working examples for both USB and network printing

For more examples and usage details, see the [example](example) project.

## Additional information

For more detailed documentation and examples, visit the [project homepage](https://github.com/midhunsankar23/aterni_usb_eth_printing).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

