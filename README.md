# aterni_usb_eth_printing

A Flutter plugin for USB and Ethernet printer support. Currently supports USB printing on Android with ESC/POS commands.

## Features

* Discover USB printers
* Connect to USB printers
* Print raw data
* Print formatted text using ESC/POS commands
* Support for common printer commands (text formatting, alignment, paper cut, etc.)

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  aterni_usb_eth_printing: ^0.0.1
```

### Android Setup

Add USB permissions to your Android Manifest (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-feature android:name="android.hardware.usb.host" />
<uses-permission android:name="android.permission.USB_PERMISSION" />
```

## Usage

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

For more examples and usage details, see the [example](example) project.

## Additional information

For more detailed documentation and examples, visit the [project homepage](https://github.com/midhunsankar23/aterni_usb_eth_printing).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

