# Network Printer Usage Guide

This guide explains how to use the network printer functionality from the `aterni_usb_eth_printing` plugin.

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  aterni_usb_eth_printing:
    git:
      url: https://github.com/your-username/aterni_usb_eth_printing.git
```

## Import

```dart
import 'package:aterni_usb_eth_printing/aterni_usb_eth_printing.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
```

## Basic Usage

### 1. Initialize the Printer

```dart
// Initialize with paper size and capability profile
final printer = NetworkPrinter(
  PaperSize.mm80,
  CapabilityProfile.load(),
  spaceBetweenRows: 5,
);
```

### 2. Connect to Network Printer

```dart
Future<void> connectToPrinter() async {
  try {
    final result = await printer.connect(
      '192.168.1.100', // Printer IP address
      port: 9100,      // Printer port (default is 9100 for most printers)
      timeout: Duration(seconds: 5),
    );
    
    if (result == PosPrintResult.success) {
      print('Connected to printer successfully');
    } else {
      print('Failed to connect: ${result.msg}');
    }
  } catch (e) {
    print('Connection error: $e');
  }
}
```

### 3. Print Text

```dart
void printSimpleText() {
  // Reset printer
  printer.reset();
  
  // Print simple text
  printer.text('Hello World!');
  
  // Print with styles
  printer.text(
    'Bold Text',
    styles: PosStyles(
      bold: true,
      align: PosAlign.center,
    ),
  );
  
  // Cut paper
  printer.cut();
}
```

### 4. Print Receipt with Formatting

```dart
void printReceipt() {
  printer.reset();
  
  // Header
  printer.text(
    'RECEIPT',
    styles: PosStyles(
      bold: true,
      align: PosAlign.center,
      height: PosTextSize.size2,
      width: PosTextSize.size2,
    ),
  );
  
  printer.emptyLines(1);
  
  // Date and time
  printer.text(
    'Date: ${DateTime.now().toString().substring(0, 19)}',
    styles: PosStyles(align: PosAlign.left),
  );
  
  printer.hr(); // Horizontal line
  
  // Items
  printer.row([
    PosColumn(text: 'Item', width: 6),
    PosColumn(text: 'Qty', width: 3, styles: PosStyles(align: PosAlign.center)),
    PosColumn(text: 'Price', width: 3, styles: PosStyles(align: PosAlign.right)),
  ]);
  
  printer.hr();
  
  printer.row([
    PosColumn(text: 'Coffee', width: 6),
    PosColumn(text: '2', width: 3, styles: PosStyles(align: PosAlign.center)),
    PosColumn(text: '\$6.00', width: 3, styles: PosStyles(align: PosAlign.right)),
  ]);
  
  printer.row([
    PosColumn(text: 'Tea', width: 6),
    PosColumn(text: '1', width: 3, styles: PosStyles(align: PosAlign.center)),
    PosColumn(text: '\$3.00', width: 3, styles: PosStyles(align: PosAlign.right)),
  ]);
  
  printer.hr();
  
  // Total
  printer.row([
    PosColumn(text: 'TOTAL', width: 9, styles: PosStyles(bold: true)),
    PosColumn(text: '\$9.00', width: 3, styles: PosStyles(bold: true, align: PosAlign.right)),
  ]);
  
  printer.emptyLines(2);
  printer.text('Thank you!', styles: PosStyles(align: PosAlign.center));
  printer.cut();
}
```

### 5. Print QR Code and Barcode

```dart
void printQRAndBarcode() {
  printer.reset();
  
  // QR Code
  printer.qrcode(
    'https://example.com',
    align: PosAlign.center,
    size: QRSize.size6,
  );
  
  printer.emptyLines(1);
  
  // Barcode
  printer.barcode(
    Barcode.code128('1234567890'),
    align: PosAlign.center,
    height: 50,
    textPos: BarcodeText.below,
  );
  
  printer.cut();
}
```

### 6. Print Image

```dart
import 'package:image/image.dart' as img;

void printImage() async {
  // Load image (you can load from assets, network, etc.)
  final bytes = await rootBundle.load('assets/logo.png');
  final image = img.decodeImage(bytes.buffer.asUint8List());
  
  if (image != null) {
    printer.reset();
    
    // Print image
    printer.image(image, align: PosAlign.center);
    
    // Or use raster image for better quality
    printer.imageRaster(
      image,
      align: PosAlign.center,
      highDensityHorizontal: true,
      highDensityVertical: true,
    );
    
    printer.cut();
  }
}
```

### 7. Disconnect

```dart
void disconnectPrinter() {
  printer.disconnect(delayMs: 100);
}
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:aterni_usb_eth_printing/aterni_usb_eth_printing.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class NetworkPrinterExample extends StatefulWidget {
  @override
  _NetworkPrinterExampleState createState() => _NetworkPrinterExampleState();
}

class _NetworkPrinterExampleState extends State<NetworkPrinterExample> {
  late NetworkPrinter printer;
  bool isConnected = false;
  String statusMessage = '';

  @override
  void initState() {
    super.initState();
    initPrinter();
  }

  void initPrinter() {
    printer = NetworkPrinter(
      PaperSize.mm80,
      CapabilityProfile.load(),
    );
  }

  Future<void> connectToPrinter() async {
    setState(() => statusMessage = 'Connecting...');
    
    try {
      final result = await printer.connect('192.168.1.100');
      
      setState(() {
        isConnected = result == PosPrintResult.success;
        statusMessage = result.msg;
      });
    } catch (e) {
      setState(() {
        isConnected = false;
        statusMessage = 'Connection error: $e';
      });
    }
  }

  void printTestReceipt() {
    if (!isConnected) return;
    
    printer.reset();
    printer.text(
      'Test Receipt',
      styles: PosStyles(bold: true, align: PosAlign.center),
    );
    printer.emptyLines(1);
    printer.text('Date: ${DateTime.now()}');
    printer.hr();
    printer.text('Thank you for testing!');
    printer.cut();
    
    setState(() => statusMessage = 'Receipt printed');
  }

  void disconnectPrinter() {
    printer.disconnect();
    setState(() {
      isConnected = false;
      statusMessage = 'Disconnected';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Network Printer')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Status: $statusMessage'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isConnected ? null : connectToPrinter,
              child: Text('Connect'),
            ),
            ElevatedButton(
              onPressed: isConnected ? printTestReceipt : null,
              child: Text('Print Test'),
            ),
            ElevatedButton(
              onPressed: isConnected ? disconnectPrinter : null,
              child: Text('Disconnect'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Available Methods

### Connection Methods
- `connect(String host, {int port, Duration timeout})` - Connect to network printer
- `disconnect({int? delayMs})` - Disconnect from printer

### Text Methods
- `text(String text, {PosStyles styles, int linesAfter})` - Print text
- `textEncoded(Uint8List textBytes, {PosStyles styles})` - Print encoded text
- `emptyLines(int n)` - Print empty lines
- `feed(int n)` - Feed paper
- `hr({String ch, int? len, int linesAfter})` - Print horizontal line

### Formatting Methods
- `setStyles(PosStyles styles)` - Set text styles
- `setGlobalFont(PosFontType font)` - Set global font
- `setGlobalCodeTable(String codeTable)` - Set code table

### Layout Methods
- `row(List<PosColumn> cols)` - Print table row
- `cut({PosCutMode mode})` - Cut paper
- `reset()` - Reset printer

### Graphics Methods
- `image(Image imgSrc, {PosAlign align})` - Print image
- `imageRaster(Image image, {PosAlign align, ...})` - Print raster image
- `qrcode(String text, {PosAlign align, QRSize size})` - Print QR code
- `barcode(Barcode barcode, {int? width, int? height})` - Print barcode

### Hardware Methods
- `beep({int n, PosBeepDuration duration})` - Make beep sound
- `drawer({PosDrawer pin})` - Open cash drawer

## Dependencies

Make sure your app includes these dependencies:

```yaml
dependencies:
  esc_pos_utils_plus:
    git:
      url: https://github.com/midhunsankar23/esc_pos_utils_plus.git
  image: ^4.0.0  # For image processing
```

## Error Handling

Always handle errors and check connection status:

```dart
try {
  final result = await printer.connect('192.168.1.100');
  if (result != PosPrintResult.success) {
    print('Connection failed: ${result.msg}');
    return;
  }
  // Print operations here
} catch (e) {
  print('Error: $e');
} finally {
  printer.disconnect();
}
```

## Common Printer IP Addresses and Ports

- **Port 9100**: Most ESC/POS printers
- **Port 515**: LPR/LPD protocol
- **Port 631**: IPP (Internet Printing Protocol)

## Troubleshooting

1. **Connection timeout**: Check IP address and network connectivity
2. **Print not working**: Ensure printer supports ESC/POS commands
3. **Characters not printing correctly**: Try different code tables
4. **Image quality issues**: Use `imageRaster` instead of `image`

## Supported Printer Brands

This network printer code works with any ESC/POS compatible printer, including:
- Epson
- Star Micronics
- Citizen
- Bixolon
- And many others
