//go:build !windows

package main

import "nexusvpn/core/storage"

func runWindowsService(token string, db *storage.Database) {
	panic("runWindowsService called on non-Windows platform")
}
