//go:build windows

package main

import "golang.org/x/sys/windows/svc"

func isWindowsServiceSession() bool {
	isInteractive, err := svc.IsAnInteractiveSession()
	return err == nil && !isInteractive
}
