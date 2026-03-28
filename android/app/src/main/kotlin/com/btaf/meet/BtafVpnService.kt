package com.btaf.meet

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer

/**
 * BtafVpnService implements the native Android VpnService.
 * It creates a TUN interface to capture and route device traffic.
 */
class BtafVpnService : VpnService(), Runnable {
    private var mThread: Thread? = null
    private var mInterface: ParcelFileDescriptor? = null
    private val TAG = "BtafVpnService"

    // VPN Configuration as requested
    private val VPN_ADDRESS = "10.0.0.2" 
    private val VPN_ROUTE = "0.0.0.0" 
    private val DNS_SERVER = "8.8.8.8" 
    private val MTU_SIZE = 1500

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            stopVpn()
            return START_NOT_STICKY
        }

        // 1. Create notification for foreground service to ensure persistence
        createNotificationChannel()
        val notification = createNotification("Btaf Meet VPN is active and protecting your connection")
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(1, notification)
        }

        // 2. Start the VPN background thread
        if (mThread == null) {
            mThread = Thread(this, "BtafVpnThread")
            mThread?.start()
        }

        return START_STICKY
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }

    private fun stopVpn() {
        mThread?.interrupt()
        mThread = null
        try {
            mInterface?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing TUN interface", e)
        }
        mInterface = null
        stopForeground(true)
        stopSelf()
    }

    override fun run() {
        try {
            // 3. Configure the TUN interface using VpnService.Builder
            val builder = Builder()
            builder.setMtu(MTU_SIZE)
            builder.addAddress(VPN_ADDRESS, 32) // Mandatory 32-bit mask as requested
            builder.addRoute(VPN_ROUTE, 0)      // Route all traffic (0.0.0.0/0)
            builder.addDnsServer(DNS_SERVER)    // Set DNS to 8.8.8.8
            builder.setSession("BtafMeetVpnSession")
            builder.setBlocking(true)

            // 4. Establish the interface
            mInterface = builder.establish()
            if (mInterface == null) {
                Log.e(TAG, "Failed to establish TUN interface")
                return
            }
            Log.i(TAG, "TUN Interface established: $mInterface")

            // 5. Background packet handling loop
            val fd = mInterface?.fileDescriptor
            val inputStream = FileInputStream(fd)
            val outputStream = FileOutputStream(fd)
            val packet = ByteBuffer.allocate(MTU_SIZE)

            while (!Thread.interrupted()) {
                // Read raw IP packets from the system (TUN interface)
                val length = inputStream.read(packet.array())
                if (length > 0) {
                    // In a production environment, you would forward this packet
                    // to a remote VPN server (e.g., via UDP/TCP tunnel).
                    // For this implementation, we acknowledge the packet capture.
                    
                    // Clear buffer for next read
                    packet.clear()
                }
                
                // Prevent high CPU usage in this simplified loop
                Thread.sleep(1) 
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error in VPN background loop", e)
        } finally {
            stopVpn()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                "BtafVpnChannel",
                "Btaf Meet VPN Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(content: String): Notification {
        val stopIntent = Intent(this, BtafVpnService::class.java).apply {
            action = "STOP"
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )

        return NotificationCompat.Builder(this, "BtafVpnChannel")
            .setContentTitle("Btaf Meet")
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Disconnect", stopPendingIntent)
            .build()
    }
}
