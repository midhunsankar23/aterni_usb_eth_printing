import 'dart:typed_data';
import 'aterni_usb_eth_printing_platform_interface.dart';

// Export network printer classes for external use
export 'network_printer/network_printer.dart';
export 'network_printer/enums.dart';

class AterniUsbEthPrinting {
  Future<String?> getPlatformVersion() {
    return AterniUsbEthPrintingPlatform.instance.getPlatformVersion();
  }

  Future<List<Map<String, dynamic>>> getUSBDeviceList() {
    return AterniUsbEthPrintingPlatform.instance.getUSBDeviceList();
  }

  Future<bool?> connect(int vendorId, int productId) {
    return AterniUsbEthPrintingPlatform.instance.connect(vendorId, productId);
  }

  Future<bool?> close() {
    return AterniUsbEthPrintingPlatform.instance.close();
  }

  Future<bool?> printText(String text) {
    return AterniUsbEthPrintingPlatform.instance.printText(text);
  }

  Future<bool?> printRawText(String text) {
    return AterniUsbEthPrintingPlatform.instance.printRawText(text);
  }

  Future<bool?> write(Uint8List data) {
    return AterniUsbEthPrintingPlatform.instance.write(data);
  }
}
