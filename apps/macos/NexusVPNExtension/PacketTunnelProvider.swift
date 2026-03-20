import Foundation
import NetworkExtension
import Api // Gomobile generated XCFramework

// This process runs totally isolated from the UI UI sandbox.
// It loads the Go Core dynamic library (`.dylib`).
class PacketTunnelProvider: NEPacketTunnelProvider {

    var coreBridge: ApiMobileBridge?

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Stage 13B: macOS Sandboxed Bridge execution
        
        // 1. Read the profile injected from the UI via Shared App Groups
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.nexusvpn"),
              let profileId = sharedDefaults.string(forKey: "TargetProfileID") else {
            completionHandler(NSError(domain: "NexusVPN", code: 1, userInfo: [NSLocalizedDescriptionKey: "No Profile Selected"]))
            return
        }
        
        guard let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nexusvpn") else {
            completionHandler(NSError(domain: "NexusVPN", code: 2, userInfo: [NSLocalizedDescriptionKey: "Shared App Group container is unavailable"]))
            return
        }

        let dbPath = sharedContainer.appendingPathComponent("nexusvpn.db").path

        // 2. Init Go Core via gomobile FFI wrapper (`ApiXCFramework`)
        var initErr: NSError?
        coreBridge = ApiNewMobileBridge(dbPath, &initErr)
        if let initErr {
            completionHandler(initErr)
            return
        }
        guard
            let tunConfigJSON = coreBridge?.getTunConfigJSON(),
            let tunConfigData = tunConfigJSON.data(using: .utf8),
            let tunConfig = try? JSONSerialization.jsonObject(with: tunConfigData) as? [String: Any]
        else {
            completionHandler(NSError(domain: "NexusVPN", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to decode TUN config payload"]))
            return
        }

        let tunnelAddress = (tunConfig["address"] as? String) ?? "172.19.0.1"
        let mtu = (tunConfig["mtu"] as? NSNumber)?.intValue ?? 1500
        
        // 3. Setup NEPacketTunnelNetworkSettings dynamically from Go payload
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: tunnelAddress)
        networkSettings.ipv4Settings = NEIPv4Settings(addresses: ["172.19.0.2"], subnetMasks: ["255.255.255.252"])
        networkSettings.ipv4Settings?.includedRoutes = [NEIPv4Route.default()]
        networkSettings.mtu = NSNumber(value: mtu)
        
        self.setTunnelNetworkSettings(networkSettings) { error in
            if let error = error {
                completionHandler(error)
                return
            }
            
            // 4. Trigger the actual Sing-box runtime inside the Extension Sandbox
            do {
                try self.coreBridge?.connect(profileId)
            } catch {
                completionHandler(error)
                return
            }
            
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Deterministic shutdown triggered from macOS System/Sandbox
        do {
            try self.coreBridge?.disconnect()
        } catch {
            NSLog("Failed to stop tunnel cleanly: \(error)")
        }
        
        self.coreBridge = nil
        completionHandler()
    }
}
