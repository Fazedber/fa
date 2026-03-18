package engine

import (
	"encoding/json"
	"nexusvpn/core/config"
)

// BuildSingBoxConfig dynamically constructs the heavily customized JSON config
// required by sing-box, combining our universal TUN settings with the specific
// proxy outbound settings (VLESS / Hysteria2) imported from Profile URLs.
func BuildSingBoxConfig(endpoint config.Endpoint, tun TunOptions) ([]byte, error) {
	
	// 1. Setup the Inbound (TUN interface)
	inbounds := []map[string]interface{}{
		{
			"type": "tun",
			"tag": "tun-in",
			"inet4_address": tun.Address,
			"auto_route": true, // Let sing-box manage OS routing table magically
			"strict_route": true, // Ensures traffic doesn't leak if tunnel drops (Kill Switch)
			"sniff": true,
		},
	}

	// 2. Extract outbound properties from endpoint
	var proxyOutbound map[string]interface{}
	err := json.Unmarshal([]byte(endpoint.Payload), &proxyOutbound)
	if err != nil {
		return nil, err
	}
	proxyOutbound["tag"] = "proxy"

	outbounds := []interface{}{
		proxyOutbound, // Our VLESS/Hysteria2 node
		map[string]interface{}{
			"type": "direct",
			"tag": "direct",
		},
		map[string]interface{}{
			"type": "block",
			"tag": "block",
		},
	}

	// 3. Assemble full document structure
	document := map[string]interface{}{
		"log": map[string]interface{}{
			"level": "warn",
		},
		"inbounds": inbounds,
		"outbounds": outbounds,
		"route": map[string]interface{}{
			"rules": []map[string]interface{}{
				// Default split tunnel rule: unconditionally bypass local requests
				{
					"ip_cidr": []string{"127.0.0.1/8", "::1/128", "192.168.0.0/16"},
					"outbound": "direct",
				},
			},
			"auto_detect_interface": true, // Critical for Hysteria2 seamless roaming
		},
	}

	return json.MarshalIndent(document, "", "  ")
}
