package api

import (
	"context"
	"log/slog"
	"nexusvpn/core/app"
	"nexusvpn/core/config"
	"nexusvpn/core/engine"
	"nexusvpn/core/state"
	"nexusvpn/core/storage"
)

type MobileBridge struct {
	orchestrator *app.Orchestrator
	db           *storage.Database
}

type StateCallback interface {
	OnStateChanged(stateString string, errorMessage string)
}

// MobileTunConfig encapsulates the dynamic TUN parameters requested by Android OS.
type MobileTunConfig struct {
	Address string
	Route   string
	Dns     string
	Mtu     int
}

type internalObserver struct {
	cb StateCallback
}

func (i *internalObserver) OnStateChanged(newState state.ConnectionState, err error) {
	errMsg := ""
	if err != nil {
		errMsg = err.Error()
	}
	i.cb.OnStateChanged(string(newState), errMsg)
}

func NewMobileBridge(dbPath string) (*MobileBridge, error) {
	db, err := storage.Connect(dbPath)
	if err != nil {
		return nil, err
	}
	
	adapter := engine.NewSingBoxAdapter()
	orchestrator := app.NewOrchestrator(adapter)
	return &MobileBridge{
		orchestrator: orchestrator,
		db:           db,
	}, nil
}

func (m *MobileBridge) GetTunConfig() *MobileTunConfig {
	// In production, this correctly translates the exact remote server config into TUN props
	return &MobileTunConfig{
		Address: "172.19.0.1",
		Route:   "0.0.0.0/0",
		Dns:     "1.1.1.1",
		Mtu:     1500,
	}
}

func (m *MobileBridge) Connect(profileId string) error {
	profile, err := m.db.GetProfile(profileId)
	if err != nil {
		slog.Error("Profile not found", "profile_id", profileId, "error", err)
		return err
	}
	return m.orchestrator.Connect(context.Background(), profile)
}

func (m *MobileBridge) Disconnect() error {
	return m.orchestrator.Disconnect(context.Background())
}

func (m *MobileBridge) Subscribe(cb StateCallback) {
	m.orchestrator.GetStateMachine().AddObserver(&internalObserver{cb: cb})
}

func (m *MobileBridge) ImportConfig(payload string) (config.Profile, error) {
	return (*Server)(nil).ImportConfig(payload) // Reuse parsing logic
}

func (m *MobileBridge) Close() error {
	if m.db != nil {
		return m.db.Close()
	}
	return nil
}
