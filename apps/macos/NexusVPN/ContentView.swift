import SwiftUI
import NetworkExtension

struct ContentView: View {
    @State private var status: String = "DISCONNECTED"
    @State private var manager: NETunnelProviderManager?

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) 
            
            VStack(spacing: 40) {
                Button(action: {
                    toggleVPN()
                }) {
                    Text(status == "CONNECTED" ? "DISCONNECT" : "CONNECT")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 200)
                        .background(status == "CONNECTED" ? Color.cyan.opacity(0.8) : Color.gray.opacity(0.5))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                }
                .buttonStyle(PlainButtonStyle())

                Text("STATUS: \(status)")
                    .foregroundColor(.gray)
                    .font(.headline)
            }
        }
        .onAppear { loadManager() }
    }

    func loadManager() {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if let managers = managers, managers.count > 0 {
                self.manager = managers[0]
            } else {
                let newManager = NETunnelProviderManager()
                newManager.protocolConfiguration = NETunnelProviderProtocol()
                newManager.protocolConfiguration?.serverAddress = "NexusVPN"
                newManager.localizedDescription = "NexusVPN"
                newManager.saveToPreferences { _ in
                    self.manager = newManager
                }
            }
        }
    }

    func toggleVPN() {
        guard let manager = manager else { return }
        
        if manager.connection.status == .disconnected || manager.connection.status == .invalid {
            // Stage 13B: Write targeted Profile ID into Apple App Groups so Extension can read it
            if let sharedDefaults = UserDefaults(suiteName: "group.com.nexusvpn") {
                sharedDefaults.set("profile-123", forKey: "TargetProfileID")
            }
            
            do {
                try manager.connection.startVPNTunnel()
                status = "CONNECTED"
            } catch {
                print("Failed to start tunnel: \(error)")
            }
        } else {
            manager.connection.stopVPNTunnel()
            status = "DISCONNECTED"
        }
    }
}
