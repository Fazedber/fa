//go:build !windows

package main

func isWindowsServiceSession() bool {
	return false
}
