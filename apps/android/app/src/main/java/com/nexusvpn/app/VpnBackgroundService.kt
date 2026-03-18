package com.nexusvpn.app

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log

class VpnBackgroundService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "START_VPN") {
            startVpn()
        } else if (intent?.action == "STOP_VPN") {
            stopVpn()
        }
        return START_STICKY
    }

    private fun startVpn() {
        try {
            // Stage 12B: Dynamic OS config resolution without static IPs in app binary
            val config = GoCoreBridge.getTunConfig()
            if (config == null) {
                Log.e("VPN", "GoCoreBridge not initialized or returned null config")
                return
            }

            val routeParts = config.route.split("/", limit = 2)
            val routeAddress = routeParts.firstOrNull().orEmpty()
            val routePrefix = routeParts.getOrNull(1)?.toIntOrNull() ?: 0

            val builder = Builder()
                .addAddress(config.address, 30) // Assuming isolated /30 subnet allocation
                .addRoute(routeAddress, routePrefix)
                .addDnsServer(config.dns)
                .setMtu(config.mtu.toInt())
                .setSession("NexusVPN")

            // establish() requests OS-level routing permissions from user
            vpnInterface = builder.establish()

            // Graceful failure check: Missing FD
            if (vpnInterface == null) {
                Log.e("VPN", "Failed to establish VPN: builder returned null. Permissions might have been revoked by User.")
                return
            }

            val fd = vpnInterface!!.fd
            Log.i("VPN", "VPN established successfully via fd=$fd")

        } catch (e: SecurityException) {
            // Hardening exception block: Prevents NullPointerException cascading crash 
            Log.e("VPN", "SecurityException: VPN permission not granted or revoked manually", e)
        } catch (e: Exception) {
            Log.e("VPN", "Error establishing VPN interface link", e)
        }
    }

    private fun stopVpn() {
        try {
            vpnInterface?.close()
            vpnInterface = null
            Log.i("VPN", "VPN interface closed seamlessly")
        } catch (e: Exception) {
            Log.e("VPN", "Error closing VPN interface", e)
        }
        stopSelf()
    }
}
