import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aterni_usb_eth_printing/aterni_usb_eth_printing.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Map<String, dynamic>> devices = [];
  final AterniUsbEthPrinting _printer = AterniUsbEthPrinting();
  bool connected = false;

  @override
  void initState() {
    super.initState();
    _getDevicelist();
  }

  Future<void> _getDevicelist() async {
    List<Map<String, dynamic>> results = [];
    try {
      results = await _printer.getUSBDeviceList();
      print("Found devices: ${results.length}");
      setState(() {
        devices = results;
      });
    } on PlatformException catch (e) {
      print("Error getting device list: ${e.message}");
    }
  }

  Future<void> _connect(int vendorId, int productId) async {
    try {
      final bool? result = await _printer.connect(vendorId, productId);
      if (result == true) {
        setState(() {
          connected = true;
        });
      }
    } on PlatformException catch (e) {
      print("Error connecting to device: ${e.message}");
    }
  }

  Future<void> _print() async {
    try {
      var data = Uint8List.fromList(
        utf8.encode("Hello world Testing ESC POS printer...\n"),
      );
      await _printer.write(data);

      // Alternative printing methods:
      // await _printer.printRawText("text\n");
      // await _printer.printText("Testing ESC POS printer...\n");
    } on PlatformException catch (e) {
      print("Error printing: ${e.message}");
    }
  }

  Future<void> _printCustomData() async {
    try {
      // Example 1: Print simple text
      var textBytes = Uint8List.fromList(utf8.encode('Hello World\n'));
      await _printer.write(textBytes);

      // Example 2: Print with formatting commands (ESC/POS commands)
      // Initialize printer
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
    } on PlatformException catch (e) {
      print("Error printing: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('USB PRINTER EXAMPLE'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _getDevicelist,
            ),
            if (connected) ...[
              IconButton(icon: const Icon(Icons.print), onPressed: _print),
              IconButton(
                icon: const Icon(Icons.print_outlined),
                onPressed: _printCustomData,
              ),
            ],
          ],
        ),
        body:
            devices.isEmpty
                ? const Center(child: Text('No USB devices found'))
                : ListView(
                  scrollDirection: Axis.vertical,
                  children: _buildList(devices),
                ),
      ),
    );
  }

  List<Widget> _buildList(List<Map<String, dynamic>> devices) {
    return devices
        .map(
          (device) => ListTile(
            onTap: () {
              _connect(
                int.parse(device['vendorId']),
                int.parse(device['productId']),
              );
            },
            leading: const Icon(Icons.usb),
            title: Text("${device['manufacturer']} ${device['productName']}"),
            subtitle: Text("${device['vendorId']} ${device['productId']}"),
          ),
        )
        .toList();
  }
}
