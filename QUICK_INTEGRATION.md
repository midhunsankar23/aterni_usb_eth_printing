# Quick Integration Guide for Network Printer

This is a step-by-step guide for integrating the network printer functionality into your Flutter app.

## Step 1: Add Dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  aterni_usb_eth_printing:
    git:
      url: https://github.com/your-username/aterni_usb_eth_printing.git
  esc_pos_utils_plus:
    git:
      url: https://github.com/midhunsankar23/esc_pos_utils_plus.git
  image: ^4.0.0  # Only if you plan to print images
```

## Step 2: Import Required Packages

```dart
import 'package:aterni_usb_eth_printing/aterni_usb_eth_printing.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
```

## Step 3: Basic Setup

```dart
class PrinterService {
  late NetworkPrinter _printer;
  bool _isConnected = false;

  Future<void> initialize() async {
    final profile = await CapabilityProfile.load();
    _printer = NetworkPrinter(PaperSize.mm80, profile);
  }

  Future<bool> connect(String ipAddress, {int port = 9100}) async {
    try {
      final result = await _printer.connect(ipAddress, port: port);
      _isConnected = result == PosPrintResult.success;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  void disconnect() {
    if (_isConnected) {
      _printer.disconnect();
      _isConnected = false;
    }
  }

  bool get isConnected => _isConnected;
}
```

## Step 4: Print Operations

```dart
extension PrintOperations on PrinterService {
  void printReceipt({
    required String title,
    required List<Map<String, dynamic>> items,
    required double total,
  }) {
    if (!_isConnected) return;

    _printer.reset();
    
    // Header
    _printer.text(title, styles: PosStyles(
      bold: true,
      align: PosAlign.center,
      height: PosTextSize.size2,
    ));
    
    _printer.emptyLines(1);
    _printer.hr();
    
    // Items
    for (final item in items) {
      _printer.row([
        PosColumn(text: item['name'], width: 8),
        PosColumn(text: item['qty'].toString(), width: 2, styles: PosStyles(align: PosAlign.center)),
        PosColumn(text: '\$${item['price']}', width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
    }
    
    _printer.hr();
    
    // Total
    _printer.row([
      PosColumn(text: 'TOTAL', width: 10, styles: PosStyles(bold: true)),
      PosColumn(text: '\$${total.toStringAsFixed(2)}', width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
    ]);
    
    _printer.emptyLines(2);
    _printer.cut();
  }

  void printQRCode(String data) {
    if (!_isConnected) return;
    
    _printer.reset();
    _printer.qrcode(data, align: PosAlign.center);
    _printer.emptyLines(1);
    _printer.cut();
  }
}
```

## Step 5: Flutter Widget Integration

```dart
class PrinterWidget extends StatefulWidget {
  @override
  _PrinterWidgetState createState() => _PrinterWidgetState();
}

class _PrinterWidgetState extends State<PrinterWidget> {
  final PrinterService _printerService = PrinterService();
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _printerService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _ipController,
          decoration: InputDecoration(labelText: 'Printer IP Address'),
        ),
        ElevatedButton(
          onPressed: () async {
            final connected = await _printerService.connect(_ipController.text);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(connected ? 'Connected' : 'Failed to connect')),
            );
            setState(() {});
          },
          child: Text('Connect'),
        ),
        if (_printerService.isConnected) ...[
          ElevatedButton(
            onPressed: () {
              _printerService.printReceipt(
                title: 'TEST RECEIPT',
                items: [
                  {'name': 'Coffee', 'qty': 2, 'price': 3.00},
                  {'name': 'Tea', 'qty': 1, 'price': 2.50},
                ],
                total: 8.50,
              );
            },
            child: Text('Print Receipt'),
          ),
          ElevatedButton(
            onPressed: () => _printerService.disconnect(),
            child: Text('Disconnect'),
          ),
        ],
      ],
    );
  }
}
```

## Common Printer IP Ranges

- **192.168.1.x** - Most home routers
- **192.168.0.x** - Alternative home router range
- **10.0.0.x** - Corporate networks
- **172.16.x.x to 172.31.x.x** - Corporate networks

## Troubleshooting

1. **Can't connect**: Check if printer is on the same network
2. **Nothing prints**: Verify printer supports ESC/POS commands
3. **Garbled text**: Try different character encodings
4. **Connection timeout**: Increase timeout duration or check firewall

## Complete Example

For a complete working example, see: `example_network_printer.dart` in the repository.
