import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aterni_usb_eth_printing/aterni_usb_eth_printing.dart';
import 'package:aterni_usb_eth_printing/network_printer/network_printer.dart';


void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

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
    
    // Delay a bit to make sure the app is fully initialized before accessing USB
    Future.delayed(const Duration(milliseconds: 500), () {
      _getDevicelist();
      
      // Set up automatic refresh every 5 seconds to detect new devices
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
      
      // If permission issue, try to refresh device list after a delay
      if (e.message?.contains('permission') ?? false) {
        Future.delayed(const Duration(seconds: 2), _getDevicelist);
      }
    }
  }

  Future<void> _print() async {
    setState(() {
      _statusMessage = 'Sending data to printer...';
      _isLoading = true;
    });
    
    try {
      var data = Uint8List.fromList(
        utf8.encode("Hello world Testing ESC POS printer...\n"),
      );
      
      final result = await _printer.write(data);
      
      setState(() {
        _isLoading = false;
        _statusMessage = result == true
            ? 'Print job sent successfully!'
            : 'Print job failed. Please check printer connection.';
      });

      // Alternative printing methods:
      // await _printer.printRawText("text\n");
      // await _printer.printText("Testing ESC POS printer...\n");
    } on PlatformException catch (e) {
      print("Error printing: ${e.message}");
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error printing: ${e.message}';
      });
    }
  }

  Future<void> _printCustomData() async {
    setState(() {
      _statusMessage = 'Sending formatted data to printer...';
      _isLoading = true;
    });
    
    try {
      // Example 1: Print simple text
      var textBytes = Uint8List.fromList(utf8.encode('Hello World\n'));
      await _printer.write(textBytes);

      // Example 2: Print with formatting commands (ESC/POS commands)
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

      final result = await _printer.write(Uint8List.fromList(bytes));
      
      setState(() {
        _isLoading = false;
        _statusMessage = result == true
            ? 'Formatted print job sent successfully!'
            : 'Print job failed. Please check printer connection.';
      });
    } on PlatformException catch (e) {
      print("Error printing: ${e.message}");
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error printing: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('USB PRINTER EXAMPLE'),
          actions: <Widget>[
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _getDevicelist(silentMode: false),
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
        body: Column(
          children: [
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8.0),
                width: double.infinity,
                color: Colors.blue.withOpacity(0.1),
                child: Text(_statusMessage,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No USB devices found'),
                          const SizedBox(height: 16),
                          if (!_isLoading)
                            ElevatedButton.icon(
                              onPressed: () => _getDevicelist(silentMode: false),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Scan for printers'),
                            ),
                        ],
                      ),
                    )
                  : ListView(
                      scrollDirection: Axis.vertical,
                      children: _buildList(devices),
                    ),
            ),
          ],
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
