package com.nexusvpn.app

import api.Api
import api.MobileBridge
import api.MobileTunConfig

object GoCoreBridge {
    private var mobileBridge: MobileBridge? = null
    
    fun initCore(dbPath: String) {
        if (mobileBridge != null) {
            return
        }

        mobileBridge = Api.newMobileBridge(dbPath)
    }

    fun getTunConfig(): MobileTunConfig? {
        return mobileBridge?.getTunConfig()
    }

    // Other bindings would be here (subscribe, connect, disconnect)
}
