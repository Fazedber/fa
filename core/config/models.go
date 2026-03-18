package config

// Endpoint identifies a VPN node.
type Endpoint struct {
	ID       string
	Address  string
	Port     int
	Protocol string // e.g. "vless", "hysteria2"
	Payload  string // Raw JSON configuration for the specific engine
}

// Profile is a user-facing entity associating routing and node.
type Profile struct {
	ID       string
	Name     string
	Endpoint Endpoint
	// TODO: Add RoutePolicy reference
}
