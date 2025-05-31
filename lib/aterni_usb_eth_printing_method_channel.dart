import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';

import 'aterni_usb_eth_printing_platform_interface.dart';

/// An implementation of [AterniUsbEthPrintingPlatform] that uses method channels.
class MethodChannelAterniUsbEthPrinting extends AterniUsbEthPrintingPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('aterni_usb_eth_printing');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<List<Map<String, dynamic>>> getUSBDeviceList() async {
    if (Platform.isAndroid) {
      List<dynamic> devices = await methodChannel.invokeMethod(
        'getUSBDeviceList',
      );
      var result =
          devices
              .cast<Map<dynamic, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
      return result;
    } else {
      return <Map<String, dynamic>>[];
    }
  }

  @override
  Future<bool?> connect(int vendorId, int productId) async {
    Map<String, dynamic> params = {
      "vendorId": vendorId,
      "productId": productId,
    };
    final bool? result = await methodChannel.invokeMethod('connect', params);
    return result;
  }

  @override
  Future<bool?> close() async {
    final bool? result = await methodChannel.invokeMethod('close');
    return result;
  }

  @override
  Future<bool?> printText(String text) async {
    Map<String, dynamic> params = {"text": text};
    final bool? result = await methodChannel.invokeMethod('printText', params);
    return result;
  }

  @override
  Future<bool?> printRawText(String text) async {
    Map<String, dynamic> params = {"raw": text};
    final bool? result = await methodChannel.invokeMethod(
      'printRawText',
      params,
    );
    return result;
  }

  @override
  Future<bool?> write(Uint8List data) async {
    Map<String, dynamic> params = {"data": data};
    final bool? result = await methodChannel.invokeMethod('write', params);
    return result;
  }
}
