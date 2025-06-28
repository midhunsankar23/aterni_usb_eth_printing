# Enum and Class Reference Guide

This guide lists all the enums and classes available when importing `aterni_usb_eth_printing`.

## Available Imports

When you import the main package, all these classes and enums are available:

```dart
import 'package:aterni_usb_eth_printing/aterni_usb_eth_printing.dart';
// Everything below is now available without additional imports
```

## Core Classes

### NetworkPrinter
Main class for network printing operations.

### PosPrintResult
Result enum for print operations with these values:
- `PosPrintResult.success`
- `PosPrintResult.timeout`
- `PosPrintResult.printerNotSelected`
- `PosPrintResult.ticketEmpty`
- `PosPrintResult.printInProgress`
- `PosPrintResult.scanInProgress`

### CapabilityProfile
Printer capability profile for ESC/POS compatibility.

### Generator
ESC/POS command generator (used internally by NetworkPrinter).

## Paper and Layout

### PaperSize
- `PaperSize.mm58` - 58mm paper width
- `PaperSize.mm80` - 80mm paper width (most common)

### PosAlign
Text alignment options:
- `PosAlign.left`
- `PosAlign.center`
- `PosAlign.right`

### PosTextSize
Text size options:
- `PosTextSize.size1` - Normal size (default)
- `PosTextSize.size2` - Double size
- `PosTextSize.size3` - Triple size
- `PosTextSize.size4` - Quadruple size
- `PosTextSize.size5` - 5x size
- `PosTextSize.size6` - 6x size
- `PosTextSize.size7` - 7x size
- `PosTextSize.size8` - 8x size (maximum)

## Text Styling

### PosStyles
Text styling class with properties:
```dart
PosStyles(
  bold: true,
  reverse: false,
  underline: false,
  align: PosAlign.center,
  height: PosTextSize.size2,
  width: PosTextSize.size2,
  fontType: PosFontType.fontA,
)
```

### PosFontType
Font type options:
- `PosFontType.fontA` - Font A (default)
- `PosFontType.fontB` - Font B (smaller/condensed)

## Table Formatting

### PosColumn
Used for creating table columns:
```dart
PosColumn(
  text: 'Item Name',
  width: 6,
  styles: PosStyles(bold: true),
)
```

## QR Codes

### QRSize
QR code size options:
- `QRSize.size1` - Smallest
- `QRSize.size2`
- `QRSize.size3`
- `QRSize.size4` - Recommended
- `QRSize.size5`
- `QRSize.size6`
- `QRSize.size7`
- `QRSize.size8` - Largest

### QRCorrection
Error correction levels:
- `QRCorrection.L` - Low (7% recovery)
- `QRCorrection.M` - Medium (15% recovery)
- `QRCorrection.Q` - Quartile (25% recovery)
- `QRCorrection.H` - High (30% recovery)

## Barcodes

### Barcode
Barcode types and creation:
```dart
// Common barcode types
Barcode.code128('1234567890')
Barcode.code39('HELLO')
Barcode.codabar('A123456B')
Barcode.ean8('12345670')
Barcode.ean13('1234567890123')
Barcode.upca('12345678901')
Barcode.upcE('123456')
```

### BarcodeText
Barcode text position:
- `BarcodeText.none` - No text
- `BarcodeText.above` - Text above barcode
- `BarcodeText.below` - Text below barcode (recommended)
- `BarcodeText.both` - Text above and below

### BarcodeFont
Barcode text font:
- `BarcodeFont.fontA` - Font A
- `BarcodeFont.fontB` - Font B

## Hardware Controls

### PosCutMode
Paper cutting modes:
- `PosCutMode.full` - Full cut (completely separate)
- `PosCutMode.partial` - Partial cut (easy tear)

### PosDrawer
Cash drawer control:
- `PosDrawer.pin2` - Use pin 2 (default)
- `PosDrawer.pin5` - Use pin 5

### PosBeepDuration
Beep duration options:
- `PosBeepDuration.beep50ms`
- `PosBeepDuration.beep100ms`
- `PosBeepDuration.beep150ms`
- `PosBeepDuration.beep200ms`
- `PosBeepDuration.beep250ms`
- `PosBeepDuration.beep300ms`
- `PosBeepDuration.beep400ms`
- `PosBeepDuration.beep450ms`

## Image Processing

### PosImageFn
Image processing functions:
- `PosImageFn.bitImageRaster` - Raster image (recommended)
- `PosImageFn.bitImageColumn` - Column format

## Usage Examples

### Text with Styling
```dart
printer.text(
  'Bold Centered Text',
  styles: PosStyles(
    bold: true,
    align: PosAlign.center,
    height: PosTextSize.size2,
  ),
);
```

### Table Row
```dart
printer.row([
  PosColumn(text: 'Item', width: 6),
  PosColumn(text: 'Qty', width: 2, styles: PosStyles(align: PosAlign.center)),
  PosColumn(text: 'Price', width: 4, styles: PosStyles(align: PosAlign.right)),
]);
```

### QR Code
```dart
printer.qrcode(
  'https://example.com',
  align: PosAlign.center,
  size: QRSize.size4,
  cor: QRCorrection.M,
);
```

### Barcode
```dart
printer.barcode(
  Barcode.code128('1234567890'),
  align: PosAlign.center,
  height: 50,
  textPos: BarcodeText.below,
  font: BarcodeFont.fontA,
);
```

### Hardware Controls
```dart
// Cut paper
printer.cut(mode: PosCutMode.full);

// Beep
printer.beep(n: 3, duration: PosBeepDuration.beep200ms);

// Open drawer
printer.drawer(pin: PosDrawer.pin2);
```

## Notes

- All these classes and enums are automatically available when you import `aterni_usb_eth_printing`
- You don't need to import `esc_pos_utils_plus` separately
- Most enums have sensible defaults, so you only need to specify them when you want non-default behavior
- For best compatibility, use `PaperSize.mm80` and `QRSize.size4` as starting points
