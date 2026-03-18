package routing

// Rule represents a split-tunnel rule
type Rule struct {
	Type  string // "domain", "ip-cidr", "process"
	Value string
}

// Policy encapsulates the routing strategy set by the user
type Policy struct {
	Mode       string // "proxy_all", "bypass_lan", "custom"
	ProxyList  []Rule
	BypassList []Rule
}

// OSBridge handles system-level routing changes (e.g. netsh, win-route commands).
// This is injected based on the OS.
type OSBridge interface {
	ApplyPolicy(p Policy) error
	ClearPolicy() error
}
