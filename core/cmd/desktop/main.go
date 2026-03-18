package main

import (
	"os"
	"os/signal"
	"syscall"
	"log/slog"
	"runtime"
	"path/filepath"
	
	"nexusvpn/core/api"
	"nexusvpn/core/app"
	"nexusvpn/core/engine"
	"nexusvpn/core/logging"
	"nexusvpn/core/storage"
)

func main() {
	logging.Init()
	slog.Info("NexusVPN Core Desktop starting...")

	// 1. Initialize database
	dbPath := getDatabasePath()
	slog.Info("Opening database", "path", dbPath)
	db, err := storage.Connect(dbPath)
	if err != nil {
		slog.Error("Failed to open database", "err", err)
		return
	}
	defer db.Close()

	// 2. Stage 12A: Security Hardening - Generate IPC Token
	token, err := generateAndSaveToken()
	if err != nil {
		slog.Error("Failed to generate IPC token. Failing fast.", "err", err)
		return
	}

	// 3. Stage 10A: NT Service Injection check
	if runtime.GOOS == "windows" && isWindowsServiceSession() {
		slog.Info("Execution detected inside Windows SCM (NT Service)")
		runWindowsService(token, db)
		return
	}

	adapter := engine.NewSingBoxAdapter()
	orchestrator := app.NewOrchestrator(adapter)
	server := api.NewServer(orchestrator, db)
	
	// Start authenticated channel
	go func() {
		if err := api.ListenAndServeGrpc(server, "127.0.0.1:50051", token); err != nil {
			slog.Error("CRITICAL: gRPC Server crashed", "error", err)
		}
	}()

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	
	slog.Info("Service running interactively. Waiting for signals...")
	<-sigs
	slog.Info("Shutting down...")
}

func getDatabasePath() string {
	if runtime.GOOS == "windows" {
		localAppData := os.Getenv("LOCALAPPDATA")
		if localAppData == "" {
			localAppData = os.Getenv("USERPROFILE")
		}
		return filepath.Join(localAppData, "NexusVPN", "profiles.db")
	}
	// Unix-like systems
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".nexusvpn", "profiles.db")
}
