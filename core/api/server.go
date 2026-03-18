package api

import (
	"context"
	"nexusvpn/core/app"
	"nexusvpn/core/config"
	"nexusvpn/core/engine"
	"nexusvpn/core/state"
	"nexusvpn/core/storage"
)

// Server implements the PlatformBridge interface.
// It wraps the Orchestrator for gRPC/gomobile access.
type Server struct {
	orchestrator *app.Orchestrator
	db           *storage.Database
}

func NewServer(o *app.Orchestrator, db *storage.Database) *Server {
	return &Server{
		orchestrator: o,
		db:           db,
	}
}

func (s *Server) Connect(ctx context.Context, profileID string) error {
	// Load profile from database
	profile, err := s.db.GetProfile(profileID)
	if err != nil {
		return err
	}
	return s.orchestrator.Connect(ctx, profile)
}

func (s *Server) Disconnect(ctx context.Context) error {
	return s.orchestrator.Disconnect(ctx)
}

func (s *Server) GetState() state.ConnectionState {
	return s.orchestrator.GetStateMachine().Current()
}

func (s *Server) SubscribeState(observer state.StateObserver) {
	s.orchestrator.GetStateMachine().AddObserver(observer)
}

func (s *Server) GetStats() (engine.TrafficStats, error) {
	return s.orchestrator.GetStats()
}

func (s *Server) ImportConfig(payload string) (config.Profile, error) {
	endpoint, err := config.ParseURI(payload)
	if err != nil {
		return config.Profile{}, err
	}

	// Save to database
	if err := s.db.SaveProfile(endpoint); err != nil {
		return config.Profile{}, err
	}

	return endpoint, nil
}
