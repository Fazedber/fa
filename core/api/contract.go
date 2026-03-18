package api

import (
	"context"
	"nexusvpn/core/config"
	"nexusvpn/core/engine"
	"nexusvpn/core/state"
)

// PlatformBridge defines the interface exposed to native shell environments.
// On Windows/macOS this maps to gRPC bounds. On Android it maps to gomobile bindings.
type PlatformBridge interface {
	Connect(ctx context.Context, profileID string) error
	Disconnect(ctx context.Context) error

	GetState() state.ConnectionState
	SubscribeState(observer state.StateObserver)

	GetStats() (engine.TrafficStats, error)
	ImportConfig(payload string) (config.Profile, error)
}
