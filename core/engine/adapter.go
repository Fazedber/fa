package engine

import "nexusvpn/core/config"

type TunOptions struct {
	MTU     int
	Address string
}

type TrafficStats struct {
	UplinkBytes   uint64
	DownlinkBytes uint64
}

// EngineAdapter is the interface for underneath protocols (e.g. sing-box).
type EngineAdapter interface {
	Start(endpoint config.Endpoint, tun TunOptions) error
	Stop() error
	GetStats() (TrafficStats, error)
}
