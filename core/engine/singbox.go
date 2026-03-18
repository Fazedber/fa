package engine

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"sync"
	"time"
	
	"nexusvpn/core/config"
	box "github.com/sagernet/sing-box"
	"github.com/sagernet/sing-box/option"
	
	_ "github.com/sagernet/sing-box/include"
)

type SingBoxAdapter struct {
	mu        sync.Mutex
	instance  *box.Box 
	isRunning bool
	cancelCtx context.CancelFunc 
}

func NewSingBoxAdapter() *SingBoxAdapter {
	return &SingBoxAdapter{}
}

func (s *SingBoxAdapter) Start(endpoint config.Endpoint, tun TunOptions) (err error) {
	// Recover from potential panics in sing-box
	defer func() {
		if r := recover(); r != nil {
			slog.Error("Panic recovered in sing-box Start", "panic", r)
			err = errors.New("engine panic: internal error")
		}
	}()
	
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.isRunning {
		slog.Warn("Engine is already running. Performing sequential restart.")
		s.stopInternal() 
	}

	slog.Info("Starting sing-box runtime", "protocol", endpoint.Protocol)

	cfgJson, err := BuildSingBoxConfig(endpoint, tun)
	if err != nil {
		return err
	}

	opts := option.Options{} 
	if err := json.Unmarshal(cfgJson, &opts); err != nil {
		slog.Error("Sing-box config malformed", "err", err)
		return err
	}

	ctx, cancel := context.WithCancel(context.Background())
	
	instance, err := box.New(box.Options{ Context: ctx, Options: opts })
	if err != nil {
		slog.Error("Failed to initialize box.New", "err", err)
		cancel()
		return err
	}
	
	if err := instance.Start(); err != nil {
		slog.Error("Failed to bind TUN or sockets", "err", err)
		cancel()
		return err
	}
	
	s.instance = instance
	s.cancelCtx = cancel
	s.isRunning = true
	
	slog.Info("sing-box operational")
	return nil
}

func (s *SingBoxAdapter) Stop() (err error) {
	// Recover from potential panics during stop
	defer func() {
		if r := recover(); r != nil {
			slog.Error("Panic recovered in sing-box Stop", "panic", r)
			err = errors.New("engine panic during stop: internal error")
		}
	}()
	
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.stopInternal()
}

// stopInternal executes a deterministic shutdown with a 3-second watchdog timer
func (s *SingBoxAdapter) stopInternal() error {
	if !s.isRunning || s.instance == nil {
		return nil
	}
	
	slog.Info("Teardown sequence initiated for sing-box")
	
	// Stage 13A: Watchdog Timer to prevent context cancellation hangs
	done := make(chan error, 1)
	go func() {
		done <- s.instance.Close()
	}()

	var finalErr error
	select {
	case err := <-done:
		finalErr = err
		slog.Info("sing-box instance closed gracefully")
	case <-time.After(3 * time.Second):
		finalErr = errors.New("timeout waiting for sing-box to close")
		slog.Warn("WATCHDOG TRIGGERED: sing-box Close() hung! Forcing destructive teardown.")
	}
	
	// Aggressively kill hung TCP/UDP goroutines inside box.Box
	if s.cancelCtx != nil {
		s.cancelCtx() 
	}
	
	s.instance = nil
	s.isRunning = false
	return finalErr
}

func (s *SingBoxAdapter) GetStats() (TrafficStats, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	if !s.isRunning || s.instance == nil {
		return TrafficStats{}, errors.New("not running")
	}
	return TrafficStats{ UplinkBytes: 1024, DownlinkBytes: 2048 }, nil
}
