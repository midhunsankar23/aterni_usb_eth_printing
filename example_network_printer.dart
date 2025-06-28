import 'package:flutter/material.dart';
import 'package:aterni_usb_eth_printing/aterni_usb_eth_printing.dart';
// Note: All esc_pos_utils_plus classes are now exported from the main package

/// Simple example showing how to use the network printer functionality
/// from the aterni_usb_eth_printing plugin.
class SimpleNetworkPrinterExample extends StatefulWidget {
  const SimpleNetworkPrinterExample({Key? key}) : super(key: key);

  @override
  _SimpleNetworkPrinterExampleState createState() =>
      _SimpleNetworkPrinterExampleState();
}

class _SimpleNetworkPrinterExampleState
    extends State<SimpleNetworkPrinterExample> {
  late NetworkPrinter printer;
  bool isConnected = false;
  String statusMessage = 'Not connected';
  final TextEditingController _ipController =
      TextEditingController(text: '192.168.1.100');
  final TextEditingController _portController =
      TextEditingController(text: '9100');

  @override
  void initState() {
    super.initState();
    _initializePrinter();
  }

  Future<void> _initializePrinter() async {
    // Initialize the network printer with 80mm paper size
    // Load the default capability profile for ESC/POS printers
    final profile = await CapabilityProfile.load();
    printer = NetworkPrinter(
      PaperSize.mm80,
      profile,
      spaceBetweenRows: 5,
    );
  }

  Future<void> _connectToPrinter() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9100;

    if (ip.isEmpty) {
      setState(() => statusMessage = 'Please enter IP address');
      return;
    }

    setState(() => statusMessage = 'Connecting...');

    try {
      final result = await printer.connect(
        ip,
        port: port,
        timeout: const Duration(seconds: 5),
      );

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

  void _printTestReceipt() {
    if (!isConnected) return;

    try {
      // Reset printer
      printer.reset();

      // Header
      printer.text(
        'TEST RECEIPT',
        styles: const PosStyles(
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
        styles: const PosStyles(align: PosAlign.left),
      );

      printer.hr();

      // Sample items
      printer.row([
        PosColumn(text: 'Item', width: 6),
        PosColumn(
            text: 'Qty',
            width: 3,
            styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
            text: 'Price',
            width: 3,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      printer.hr();

      printer.row([
        PosColumn(text: 'Coffee', width: 6),
        PosColumn(
            text: '2',
            width: 3,
            styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
            text: '\$6.00',
            width: 3,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      printer.row([
        PosColumn(text: 'Tea', width: 6),
        PosColumn(
            text: '1',
            width: 3,
            styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
            text: '\$3.00',
            width: 3,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      printer.hr();

      // Total
      printer.row([
        PosColumn(text: 'TOTAL', width: 9, styles: const PosStyles(bold: true)),
        PosColumn(
            text: '\$9.00',
            width: 3,
            styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);

      printer.emptyLines(2);

      // Footer
      printer.text(
        'Thank you for your purchase!',
        styles: const PosStyles(align: PosAlign.center),
      );

      printer.emptyLines(1);

      // QR Code
      printer.qrcode(
        'https://github.com/your-repo/aterni_usb_eth_printing',
        align: PosAlign.center,
        size: QRSize.size4,
      );

      // Cut paper
      printer.cut();

      setState(() => statusMessage = 'Test receipt printed successfully');
    } catch (e) {
      setState(() => statusMessage = 'Print error: $e');
    }
  }

  void _printSimpleText() {
    if (!isConnected) return;

    try {
      printer.reset();

      printer.text(
        'Hello from Network Printer!',
        styles: const PosStyles(
          bold: true,
          align: PosAlign.center,
        ),
      );

      printer.emptyLines(1);
      printer.text('This is a simple text print test.');
      printer.emptyLines(2);
      printer.cut();

      setState(() => statusMessage = 'Simple text printed');
    } catch (e) {
      setState(() => statusMessage = 'Print error: $e');
    }
  }

  void _disconnectPrinter() {
    printer.disconnect();
    setState(() {
      isConnected = false;
      statusMessage = 'Disconnected';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Printer Example'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.green.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Status: $statusMessage',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isConnected
                      ? Colors.green.shade800
                      : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // IP Address input
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Printer IP Address',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
              ),
              enabled: !isConnected,
            ),

            const SizedBox(height: 10),

            // Port input
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '9100',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              enabled: !isConnected,
            ),

            const SizedBox(height: 20),

            // Connect/Disconnect button
            ElevatedButton(
              onPressed: isConnected ? _disconnectPrinter : _connectToPrinter,
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.red : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                isConnected ? 'Disconnect' : 'Connect',
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),

            // Print buttons
            const Text(
              'Print Options:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: isConnected ? _printSimpleText : null,
              icon: const Icon(Icons.text_fields),
              label: const Text('Print Simple Text'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: isConnected ? _printTestReceipt : null,
              icon: const Icon(Icons.receipt),
              label: const Text('Print Test Receipt'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            // Instructions
            const Expanded(
              child: SingleChildScrollView(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('1. Enter your network printer\'s IP address'),
                        Text(
                            '2. Enter the port (usually 9100 for ESC/POS printers)'),
                        Text('3. Tap "Connect" to establish connection'),
                        Text('4. Use the print buttons to test printing'),
                        Text('5. Tap "Disconnect" when finished'),
                        SizedBox(height: 12),
                        Text(
                          'Note:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                            'Make sure your printer supports ESC/POS commands and is connected to the same network.'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (isConnected) {
      printer.disconnect();
    }
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
