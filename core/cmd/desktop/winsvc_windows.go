//go:build windows

package main

import (
	"log/slog"
	
	"golang.org/x/sys/windows/svc"
	"nexusvpn/core/api"
	"nexusvpn/core/app"
	"nexusvpn/core/engine"
	"nexusvpn/core/storage"
)

type nexusService struct {
	token string
	db    *storage.Database
}

func (m *nexusService) Execute(args []string, r <-chan svc.ChangeRequest, changes chan<- svc.Status) (ssec bool, errno uint32) {
	const cmdsAccepted = svc.AcceptStop | svc.AcceptShutdown
	changes <- svc.Status{State: svc.StartPending}
	
	adapter := engine.NewSingBoxAdapter()
	orchestrator := app.NewOrchestrator(adapter)
	server := api.NewServer(orchestrator, m.db)
	
	go func() {
		if err := api.ListenAndServeGrpc(server, "127.0.0.1:50051", m.token); err != nil {
			slog.Error("gRPC Service failed", "err", err)
		}
	}()

	changes <- svc.Status{State: svc.Running, Accepts: cmdsAccepted}
	slog.Info("Windows NT Service running")

	for c := range r {
		switch c.Cmd {
		case svc.Interrogate:
			changes <- c.CurrentStatus
		case svc.Stop, svc.Shutdown:
			slog.Info("Windows NT Service shutdown requested via Service Control Manager")
			changes <- svc.Status{State: svc.StopPending}
			// Force a graceful tunnel teardown since OS is killing us
			orchestrator.Disconnect(nil)
			return
		}
	}
	return
}

func runWindowsService(token string, db *storage.Database) {
	err := svc.Run("NexusVPN", &nexusService{token: token, db: db})
	if err != nil {
		slog.Error("Service failed", "err", err)
	}
}
