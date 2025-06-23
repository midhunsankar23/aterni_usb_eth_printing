package com.aterni.aterni_usb_eth_printing

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Log

/**
 * Explicit BroadcastReceiver for USB permissions to address issues with implicit receivers
 * in newer Android versions
 */
class UsbPermissionReceiver : BroadcastReceiver() {
    
    companion object {
        private const val LOG_TAG = "USB Permission Receiver"
        const val ACTION_USB_PERMISSION = "com.aterni.aterni_usb_eth_printing.USB_PERMISSION"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        
        if (ACTION_USB_PERMISSION == action) {
            Log.d(LOG_TAG, "Received USB permission response")
            
            val usbDevice = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(UsbManager.EXTRA_DEVICE) as UsbDevice?
            }
            
            if (usbDevice == null) {
                Log.e(LOG_TAG, "USB device is null in permission response")
                return
            }
            
            val permissionGranted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
            
            if (permissionGranted) {
                Log.i(
                    LOG_TAG,
                    "Permission granted for device ${usbDevice.deviceId}, vendor_id: ${usbDevice.vendorId}, product_id: ${usbDevice.productId}"
                )
                
                // Forward the event to our main application
                val forwardIntent = Intent(ACTION_USB_PERMISSION)
                forwardIntent.putExtra(UsbManager.EXTRA_DEVICE, usbDevice)
                forwardIntent.putExtra(UsbManager.EXTRA_PERMISSION_GRANTED, true)
                context.sendBroadcast(forwardIntent)
                
            } else {
                Log.e(
                    LOG_TAG,
                    "User refused USB device permission for ${usbDevice.deviceName}"
                )
                
                // Forward the denial as well
                val forwardIntent = Intent(ACTION_USB_PERMISSION)
                forwardIntent.putExtra(UsbManager.EXTRA_DEVICE, usbDevice)
                forwardIntent.putExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                context.sendBroadcast(forwardIntent)
            }
        }
    }
}
