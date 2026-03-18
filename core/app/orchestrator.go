package app

import (
	"context"
	"nexusvpn/core/config"
	"nexusvpn/core/engine"
	"nexusvpn/core/state"
)

// Orchestrator glues together the State Machine, Engine, and Routing.
type Orchestrator struct {
	sm      *StateMachine
	adapter engine.EngineAdapter
}

func NewOrchestrator(adapter engine.EngineAdapter) *Orchestrator {
	return &Orchestrator{
		sm:      NewStateMachine(),
		adapter: adapter,
	}
}

// Connect initiates the VPN tunnel.
func (o *Orchestrator) Connect(ctx context.Context, profile config.Profile) error {
	o.sm.Transition(state.StateConnecting, nil)

	// TODO: fetch configs, set routes
	tunOpts := engine.TunOptions{MTU: 1500, Address: "172.19.0.1/30"}
	
	err := o.adapter.Start(profile.Endpoint, tunOpts)
	if err != nil {
		o.sm.Transition(state.StateFailed, err)
		return err
	}

	o.sm.Transition(state.StateConnected, nil)
	return nil
}

// Disconnect stops the VPN tunnel.
func (o *Orchestrator) Disconnect(ctx context.Context) error {
	o.sm.Transition(state.StateDisconnecting, nil)
	err := o.adapter.Stop()
	o.sm.Transition(state.StateDisconnected, err)
	return err
}

func (o *Orchestrator) GetStateMachine() *StateMachine {
	return o.sm
}

// GetStats returns traffic statistics from the engine
func (o *Orchestrator) GetStats() (engine.TrafficStats, error) {
	return o.adapter.GetStats()
}
