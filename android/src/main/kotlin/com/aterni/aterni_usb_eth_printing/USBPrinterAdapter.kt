package com.aterni.aterni_usb_eth_printing

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Base64
import android.util.Log
import android.widget.Toast
import java.nio.charset.Charset


class USBPrinterAdapter {

    private var mInstance: USBPrinterAdapter? = null

    private val LOG_TAG = "Flutter USB Printer"
    private var mContext: Context? = null
    private var mUSBManager: UsbManager? = null
    private var mPermissionIndent: PendingIntent? = null
    private var mUsbDevice: UsbDevice? = null
    private var mUsbDeviceConnection: UsbDeviceConnection? = null
    private var mUsbInterface: UsbInterface? = null
    private var mEndPoint: UsbEndpoint? = null

    private val ACTION_USB_PERMISSION = "com.aterni.aterni_usb_eth_printing.USB_PERMISSION"

    // Chunking configuration
    private val DEFAULT_CHUNK_SIZE = 8192 // 8KB chunks
    private val MAX_RETRIES = 3
    private val CHUNK_TIMEOUT = 5000 // 5 seconds per chunk
    private val INTER_CHUNK_DELAY = 10L // 10ms between chunks

    fun getInstance(): USBPrinterAdapter? {
        if (mInstance == null) {
            mInstance = this;
        }
        return mInstance
    }

    private val mUsbDeviceReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.action
            if (ACTION_USB_PERMISSION == action) {
                synchronized(this) {
                    val usbDevice =
                        intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        Log.i(
                            LOG_TAG,
                            "Success to grant permission for device " + usbDevice!!.deviceId + ", vendor_id: " + usbDevice.vendorId + " product_id: " + usbDevice.productId
                        )
                        mUsbDevice = usbDevice
                    } else {
                        Toast.makeText(
                            context,
                            "User refused to give USB device permissions" + usbDevice!!.deviceName,
                            Toast.LENGTH_LONG
                        ).show()
                    }
                }
            } else if (UsbManager.ACTION_USB_DEVICE_DETACHED == action) {
                if (mUsbDevice != null) {
                    Toast.makeText(context, "USB device has been turned off", Toast.LENGTH_LONG)
                        .show()
                    closeConnectionIfExists()
                }
            }
        }
    }

    fun init(reactContext: Context?) {
        mContext = reactContext
        mUSBManager = mContext!!.getSystemService(Context.USB_SERVICE) as UsbManager
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            mPermissionIndent = PendingIntent.getBroadcast(
                mContext!!,
                0,
                Intent(ACTION_USB_PERMISSION),
                PendingIntent.FLAG_IMMUTABLE
            )
        } else {
            mPermissionIndent = PendingIntent.getBroadcast(
                mContext!!,
                0,
                Intent(ACTION_USB_PERMISSION),
                0
            )
        }
        val filter = IntentFilter(ACTION_USB_PERMISSION)
        filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            mContext!!.registerReceiver(mUsbDeviceReceiver, filter, 0x4)
        } else {
            mContext!!.registerReceiver(mUsbDeviceReceiver, filter)
        }
        Log.v(LOG_TAG, "USB Printer initialized")
    }

    fun closeConnectionIfExists() {
        if (mUsbDeviceConnection != null) {
            mUsbDeviceConnection!!.releaseInterface(mUsbInterface)
            mUsbDeviceConnection!!.close()
            mUsbInterface = null
            mEndPoint = null
            mUsbDeviceConnection = null
        }
    }

    fun getDeviceList(): List<UsbDevice> {
        if (mUSBManager == null) {
            Toast.makeText(
                mContext,
                "USB Manager is not initialized while get device list",
                Toast.LENGTH_LONG
            ).show()
            return emptyList()
        }
        return ArrayList(mUSBManager!!.deviceList.values)
    }

    fun selectDevice(vendorId: Int, productId: Int): Boolean {
        if (mUsbDevice == null || mUsbDevice!!.vendorId != vendorId || mUsbDevice!!.productId != productId) {
            closeConnectionIfExists()
            val usbDevices = getDeviceList()
            for (usbDevice in usbDevices) {
                if (usbDevice.vendorId == vendorId && usbDevice.productId == productId) {
                    Log.v(
                        LOG_TAG,
                        "Request for device: vendor_id: " + usbDevice.vendorId + ", product_id: " + usbDevice.productId
                    )
                    closeConnectionIfExists()
                    mUSBManager!!.requestPermission(usbDevice, mPermissionIndent)
                    mUsbDevice = usbDevice
                    return true
                }
            }
            return false
        }
        return true
    }

    private fun openConnection(): Boolean {
        if (mUsbDevice == null) {
            Log.e(LOG_TAG, "USB Device is not initialized")
            return false
        }
        if (mUSBManager == null) {
            Log.e(LOG_TAG, "USB Manager is not initialized")
            return false
        }
        if (mUsbDeviceConnection != null) {
            Log.i(LOG_TAG, "USB Connection already connected")
            return true
        }
        
        val usbInterface = mUsbDevice!!.getInterface(0)
        for (i in 0 until usbInterface.endpointCount) {
            val ep = usbInterface.getEndpoint(i)
            if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK) {
                if (ep.direction == UsbConstants.USB_DIR_OUT) {
                    val usbDeviceConnection = mUSBManager!!.openDevice(mUsbDevice)
                    if (usbDeviceConnection == null) {
                        Log.e(LOG_TAG, "failed to open USB Connection")
                        return false
                    }
                    Toast.makeText(mContext, "Device connected", Toast.LENGTH_SHORT).show()
                    return if (usbDeviceConnection.claimInterface(usbInterface, true)) {
                        mEndPoint = ep
                        mUsbInterface = usbInterface
                        mUsbDeviceConnection = usbDeviceConnection
                        true
                    } else {
                        usbDeviceConnection.close()
                        Log.e(LOG_TAG, "failed to claim usb connection")
                        false
                    }
                }
            }
        }
        return false
    }

    /**
     * Enhanced chunked transfer method with retry mechanism
     */
    private fun transferWithChunking(bytes: ByteArray, chunkSize: Int = DEFAULT_CHUNK_SIZE): Boolean {
        val totalSize = bytes.size
        var offset = 0
        var transferredBytes = 0
        
        Log.i(LOG_TAG, "Starting chunked transfer: $totalSize bytes, chunk size: $chunkSize")
        
        while (offset < totalSize) {
            val remainingBytes = totalSize - offset
            val currentChunkSize = minOf(chunkSize, remainingBytes)
            
            // Create chunk from the original array
            val chunk = bytes.sliceArray(offset until offset + currentChunkSize)
            
            // Transfer with retry mechanism
            val result = transferChunkWithRetry(chunk, MAX_RETRIES)
            
            if (result < 0) {
                Log.e(LOG_TAG, "Failed to transfer chunk at offset $offset (size: $currentChunkSize)")
                return false
            }
            
            transferredBytes += result
            offset += currentChunkSize
            
            // Log progress for large transfers
            if (totalSize > 10000) {
                val progress = (transferredBytes * 100) / totalSize
                Log.i(LOG_TAG, "Transfer progress: $progress% ($transferredBytes/$totalSize bytes)")
            }
            
            // Small delay between chunks to prevent overwhelming the printer
            if (offset < totalSize) {
                Thread.sleep(INTER_CHUNK_DELAY)
            }
        }
        
        Log.i(LOG_TAG, "Transfer completed successfully: $transferredBytes bytes")
        return true
    }

    /**
     * Transfer a single chunk with retry mechanism
     */
    private fun transferChunkWithRetry(chunk: ByteArray, maxRetries: Int): Int {
        var attempts = 0
        
        while (attempts < maxRetries) {
            if (attempts > 0) {
                Log.w(LOG_TAG, "Retrying chunk transfer, attempt ${attempts + 1}")
                Thread.sleep(100) // Wait before retry
            }
            
            val result = mUsbDeviceConnection!!.bulkTransfer(
                mEndPoint, 
                chunk, 
                chunk.size, 
                CHUNK_TIMEOUT
            )
            
            if (result >= 0) {
                if (attempts > 0) {
                    Log.i(LOG_TAG, "Chunk transfer succeeded on retry $attempts")
                }
                return result
            }
            
            Log.w(LOG_TAG, "Chunk transfer failed, result: $result")
            attempts++
        }
        
        Log.e(LOG_TAG, "Chunk transfer failed after $maxRetries attempts")
        return -1
    }

    /**
     * Enhanced printText method with chunking
     */
    fun printText(text: String): Boolean {
        Log.v(LOG_TAG, "start to print text")
        val isConnected = openConnection()
        return if (isConnected) {
            Log.v(LOG_TAG, "Connected to device")
            Thread {
                val bytes = text.toByteArray(Charset.forName("UTF-8"))
                Log.i(LOG_TAG, "Converting text to ${bytes.size} bytes")
                val success = transferWithChunking(bytes)
                Log.i(LOG_TAG, "Text transfer result: $success")
            }.start()
            true
        } else {
            Log.v(LOG_TAG, "failed to connected to device")
            false
        }
    }

    /**
     * Enhanced printRawText method with chunking
     */
    fun printRawText(data: String): Boolean {
        Log.v(LOG_TAG, "start to print raw data")
        val isConnected = openConnection()
        return if (isConnected) {
            Log.v(LOG_TAG, "Connected to device")
            Thread {
                val bytes = Base64.decode(data, Base64.DEFAULT)
                Log.i(LOG_TAG, "Decoded ${bytes.size} bytes from base64")
                val success = transferWithChunking(bytes)
                Log.i(LOG_TAG, "Raw data transfer result: $success")
            }.start()
            true
        } else {
            Log.v(LOG_TAG, "failed to connected to device")
            false
        }
    }

    /**
     * Enhanced write method with chunking
     */
    fun write(bytes: ByteArray): Boolean {
        Log.v(LOG_TAG, "start to print raw data, size: ${bytes.size} bytes")
        val isConnected = openConnection()
        return if (isConnected) {
            Log.v(LOG_TAG, "Connected to device")
            Thread {
                val success = transferWithChunking(bytes)
                Log.i(LOG_TAG, "Write transfer result: $success")
            }.start()
            true
        } else {
            Log.v(LOG_TAG, "failed to connected to device")
            false
        }
    }

    /**
     * Optional: Method to configure chunk size for specific printers
     */
    fun writeWithCustomChunkSize(bytes: ByteArray, chunkSize: Int): Boolean {
        Log.v(LOG_TAG, "start to print raw data with custom chunk size: $chunkSize")
        val isConnected = openConnection()
        return if (isConnected) {
            Log.v(LOG_TAG, "Connected to device")
            Thread {
                val success = transferWithChunking(bytes, chunkSize)
                Log.i(LOG_TAG, "Custom chunk transfer result: $success")
            }.start()
            true
        } else {
            Log.v(LOG_TAG, "failed to connected to device")
            false
        }
    }
}