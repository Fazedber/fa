package com.nexusvpn.app

import api.api.Api
import api.api.MobileBridge
import org.json.JSONObject

data class TunConfig(
    val address: String,
    val route: String,
    val dns: String,
    val mtu: Int
)

object GoCoreBridge {
    private var mobileBridge: MobileBridge? = null
    
    fun initCore(dbPath: String) {
        if (mobileBridge != null) {
            return
        }

        mobileBridge = Api.newMobileBridge(dbPath)
    }

    fun getTunConfig(): TunConfig? {
        val rawConfig = mobileBridge?.getTunConfigJSON() ?: return null
        val json = JSONObject(rawConfig)
        return TunConfig(
            address = json.optString("address", "172.19.0.1"),
            route = json.optString("route", "0.0.0.0/0"),
            dns = json.optString("dns", "1.1.1.1"),
            mtu = json.optInt("mtu", 1500)
        )
    }

    // Other bindings would be here (subscribe, connect, disconnect)
}
