import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:typed_data';

import 'aterni_usb_eth_printing_method_channel.dart';

abstract class AterniUsbEthPrintingPlatform extends PlatformInterface {
  /// Constructs a AterniUsbEthPrintingPlatform.
  AterniUsbEthPrintingPlatform() : super(token: _token);

  static final Object _token = Object();

  static AterniUsbEthPrintingPlatform _instance =
      MethodChannelAterniUsbEthPrinting();

  /// The default instance of [AterniUsbEthPrintingPlatform] to use.
  ///
  /// Defaults to [MethodChannelAterniUsbEthPrinting].
  static AterniUsbEthPrintingPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AterniUsbEthPrintingPlatform] when
  /// they register themselves.
  static set instance(AterniUsbEthPrintingPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List<Map<String, dynamic>>> getUSBDeviceList() {
    throw UnimplementedError('getUSBDeviceList() has not been implemented.');
  }

  Future<bool?> connect(int vendorId, int productId) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  Future<bool?> close() {
    throw UnimplementedError('close() has not been implemented.');
  }

  Future<bool?> printText(String text) {
    throw UnimplementedError('printText() has not been implemented.');
  }

  Future<bool?> printRawText(String text) {
    throw UnimplementedError('printRawText() has not been implemented.');
  }

  Future<bool?> write(Uint8List data) {
    throw UnimplementedError('write() has not been implemented.');
  }
}
