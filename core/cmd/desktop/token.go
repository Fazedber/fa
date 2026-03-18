package main

import (
	"crypto/rand"
	"encoding/hex"
	"os"
	"path/filepath"
)

// generateAndSaveToken generates a cryptographically secure 32-byte token
// and saves it to LocalAppData so that WinUI client can read it for gRPC API calls.
func generateAndSaveToken() (string, error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	token := hex.EncodeToString(bytes)
	
	// Use LocalAppData instead of ProgramData for user-specific storage
	localAppData := os.Getenv("LOCALAPPDATA")
	if localAppData == "" {
		localAppData = os.Getenv("USERPROFILE")
	}
	
	dir := filepath.Join(localAppData, "NexusVPN")
	// Create directory with restricted permissions (0700)
	if err := os.MkdirAll(dir, 0700); err != nil {
		return "", err
	}
	
	path := filepath.Join(dir, "grpc.token")
	// Write token with restricted permissions (0600)
	err := os.WriteFile(path, []byte(token), 0600)
	
	return token, err
}
