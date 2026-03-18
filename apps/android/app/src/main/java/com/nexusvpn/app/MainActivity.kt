package com.nexusvpn.app

import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Load embedded SQLite & Go Machine
        GoCoreBridge.initCore(filesDir.resolve("nexusvpn.db").absolutePath)

        setContent {
            NexusVPNTheme {
                MainScreen(
                    onConnectClick = { startVpnService() },
                    onDisconnectClick = { stopVpnService() }
                )
            }
        }
    }

    private fun startVpnService() {
        val intent = VpnService.prepare(this)
        if (intent != null) { // Never connected before
            startActivityForResult(intent, 0)
        } else { // Permission granted previously
            val serviceIntent = Intent(this, VpnBackgroundService::class.java).apply {
                action = "START_VPN"
                putExtra("PROFILE_ID", "default-profile")
            }
            startService(serviceIntent)
            // Note: On Android 8+ we should use startForegroundService, handled next
        }
    }

    private fun stopVpnService() {
        val serviceIntent = Intent(this, VpnBackgroundService::class.java).apply {
            action = "STOP_VPN"
        }
        startService(serviceIntent)
    }
}

@Composable
fun MainScreen(onConnectClick: () -> Unit, onDisconnectClick: () -> Unit) {
    // Jetpack Compose reactive state binding
    val viewState by AppState.vpnState.collectAsState()

    // Smooth neon color transitions inside the big button
    val buttonNeonColor by animateColorAsState(
        targetValue = when (viewState) {
            VpnState.CONNECTED -> Color(0xFF00FFCC) // Neon Cyan
            VpnState.CONNECTING, VpnState.RECONNECTING -> Color(0xFFFFAA00) // Neon Orange
            else -> Color.DarkGray
        }
    )

    Surface(
        color = Color(0xFF0F0F12), // Deep App Background
        modifier = Modifier.fillMaxSize()
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // "Glass" glow wrapper around button
            Box(
                modifier = Modifier
                    .size(200.dp)
                    .clip(CircleShape)
                    .background(buttonNeonColor.copy(alpha = 0.5f)),
                contentAlignment = Alignment.Center
            ) {
                Button(
                    onClick = {
                        if (viewState == VpnState.CONNECTED) onDisconnectClick() else onConnectClick()
                    },
                    modifier = Modifier.size(180.dp),
                    shape = CircleShape,
                    colors = ButtonDefaults.buttonColors(containerColor = Color.Black)
                ) {
                    Text(
                        text = if (viewState == VpnState.CONNECTED) "DISCONNECT" else "CONNECT",
                        color = Color.White,
                        style = MaterialTheme.typography.titleLarge
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(40.dp))
            
            Text(
                text = "STATUS: ${viewState.name}",
                color = buttonNeonColor,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}

@Composable
fun NexusVPNTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = darkColorScheme(
            background = Color(0xFF0F0F12),
            onBackground = Color.White
        ),
        content = content
    )
}
