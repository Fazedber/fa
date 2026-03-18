package com.nexusvpn.app

import api.Api
import api.MobileBridge
import api.MobileTunConfig

object GoCoreBridge {
    private var mobileBridge: MobileBridge? = null
    
    fun initCore() {
        mobileBridge = Api.newMobileBridge()
    }

    fun getTunConfig(): MobileTunConfig? {
        return mobileBridge?.tunConfig()
    }

    // Other bindings would be here (subscribe, connect, disconnect)
}
