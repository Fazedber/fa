package com.nexusvpn.app

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

// Kotlin mirror of Go's core/state connection enum constants
enum class VpnState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    RECONNECTING,
    DISCONNECTING,
    FAILED
}

/**
 * Global reactive State holder. 
 * Jetpack Compose UI listens to this Flow directly.
 */
object AppState {
    private val _vpnState = MutableStateFlow(VpnState.DISCONNECTED)
    val vpnState: StateFlow<VpnState> = _vpnState.asStateFlow()

    fun updateState(newState: VpnState) {
        _vpnState.value = newState
    }
}

/**
 * Implements the Go interface `nexusvpn.state.StateObserver`.
 * As soon as Go changes state (e.g. from CONNECTING to CONNECTED), 
 * it triggers this, triggering immediate Compose UI re-renders.
 */
class StateObserverImpl /* : nexusvpn.state.StateObserver */ {
    
    // override fun OnStateChanged(newState: String, err: Exception?) {
    //     try {
    //         val stateEnum = VpnState.valueOf(newState)
    //         AppState.updateState(stateEnum)
    //     } catch (e: IllegalArgumentException) {
    //         AppState.updateState(VpnState.FAILED)
    //     }
    // }
}
