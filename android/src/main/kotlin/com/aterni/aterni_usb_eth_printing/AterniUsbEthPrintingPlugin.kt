package com.aterni.aterni_usb_eth_printing

import android.app.Activity
import android.content.Context
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result



/** AterniUsbEthPrintingPlugin */
class AterniUsbEthPrintingPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private var adapter: USBPrinterAdapter? = null
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var activity: Activity
  private lateinit var context: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    try {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "aterni_usb_eth_printing")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        adapter = USBPrinterAdapter().getInstance()
        
        // We don't initialize adapter here - it needs an Activity context for proper permission handling
        // It will be initialized in onAttachedToActivity
        
        print("AterniUsbEthPrintingPlugin attached to engine")
    } catch (e: Exception) {
        print("Error attaching to engine: ${e.message}")
        e.printStackTrace()
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    try {
        when (call.method) {
            "getUSBDeviceList" -> {
                getUSBDeviceList(result)
            }
            "connect" -> {
                val vendorId = call.argument<Int>("vendorId")
                val productId = call.argument<Int>("productId")
                
                if (vendorId == null || productId == null) {
                    result.error(
                        "INVALID_ARGUMENT", 
                        "vendorId and productId must be provided", 
                        null
                    )
                } else {
                    connect(vendorId, productId, result)
                }
            }
            "close" -> {
                close(result)
            }
            "printText" -> {
                val text = call.argument<String>("text")
                printText(text, result)
            }
            "printRawText" -> {
                val raw = call.argument<String>("raw")
                printRawText(raw, result)
            }
            "write" -> {
                val data = call.argument<ByteArray>("data")
                write(data, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    } catch (e: Exception) {
        // Handle any unexpected exceptions
        result.error(
            "METHOD_CALL_ERROR",
            "Error executing method ${call.method}: ${e.message}",
            e.stackTraceToString()
        )
    }
  }

  private fun getUSBDeviceList(result: Result) {

    val usbDevices = adapter!!.getDeviceList()
    val list = ArrayList<HashMap<String, String?>>()
    for (usbDevice in usbDevices) {
      val deviceMap: HashMap<String, String?> = HashMap()
      deviceMap["deviceName"] = usbDevice.deviceName
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        deviceMap["manufacturer"] = usbDevice.manufacturerName
      }else{
        deviceMap["manufacturer"] = "unknown";
      }
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        deviceMap["productName"] = usbDevice.productName
      }else{
        deviceMap["productName"] = "unknown";
      }
      deviceMap["deviceId"] = Integer.toString(usbDevice.deviceId)
      deviceMap["vendorId"] = Integer.toString(usbDevice.vendorId)
      deviceMap["productId"] = Integer.toString(usbDevice.productId)
      list.add(deviceMap)
      print("usbDevice ${usbDevice}");
    }
    result.success(list)
  }

  private fun connect(vendorId: Int, productId: Int, result: Result) {
    if (!adapter!!.selectDevice(vendorId!!, productId!!)) {
      result.success(false)
    } else {
      result.success(true)
    }
  }

  private fun close(result: Result) {
    adapter!!.closeConnectionIfExists()
    result.success(true)
  }

  private fun printText(text : String?, result  :Result) {
    text?.let { adapter!!.printText(it) };
    result.success(true);
  }

  private fun printRawText(base64Data: String?, result: Result) {
    adapter!!.printRawText(base64Data!!)
    result.success(true)
  }

  private fun write(bytes: ByteArray?, result: Result) {
    if (bytes == null) {
        result.error("WRITE_ERROR", "No data provided for printing", null)
        return
    }
    
    try {
        val success = adapter!!.write(bytes)
        if (success) {
            result.success(true)
        } else {
            result.error(
                "PRINTER_ERROR",
                "Failed to write to printer. Check connection and permissions.",
                null
            )
        }
    } catch (e: Exception) {
        result.error(
            "WRITE_EXCEPTION",
            "Exception while writing to printer: ${e.message}",
            e.stackTraceToString()
        )
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    try {
        print("onAttachedToActivity")
        activity = binding.activity
        
        // Initialize the adapter with the activity context for proper permission handling
        adapter!!.init(activity)
        
        // Add activity result listeners if needed for permission handling
        print("USB Printer adapter initialized with activity context")
    } catch (e: Exception) {
        print("Error in onAttachedToActivity: ${e.message}")
        e.printStackTrace()
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    // This call will be followed by onReattachedToActivityForConfigChanges().
    print("onDetachedFromActivityForConfigChanges");
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    print("onAttachedToActivity")
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    // This call will be followed by onDetachedFromActivity().
    print("onDetachedFromActivity")
  }
}
