package api

import (
	"context"
	"encoding/json"

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

type tunConfigPayload struct {
	Address string `json:"address"`
	Route   string `json:"route"`
	Dns     string `json:"dns"`
	Mtu     int    `json:"mtu"`
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

func (m *MobileBridge) GetTunConfigJSON() string {
	payload, err := json.Marshal(tunConfigPayload{
		Address: "172.19.0.1",
		Route:   "0.0.0.0/0",
		Dns:     "1.1.1.1",
		Mtu:     1500,
	})
	if err != nil {
		return "{\"address\":\"172.19.0.1\",\"route\":\"0.0.0.0/0\",\"dns\":\"1.1.1.1\",\"mtu\":1500}"
	}

	return string(payload)
}

func (m *MobileBridge) Connect(profileID string) error {
	profile, err := m.db.GetProfile(profileID)
	if err != nil {
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

func (m *MobileBridge) ImportConfig(payload string) (string, error) {
	profile, err := config.ParseURI(payload)
	if err != nil {
		return "", err
	}

	if err := m.db.SaveProfile(profile); err != nil {
		return "", err
	}

	return profile.ID, nil
}

func (m *MobileBridge) Close() error {
	if m.db != nil {
		return m.db.Close()
	}

	return nil
}
