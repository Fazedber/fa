package logging

import (
	"bytes"
	"context"
	"log/slog"
	"strings"
	"testing"
)

func TestRedactionHandler(t *testing.T) {
	// Capture log output
	var buf bytes.Buffer
	opts := &slog.HandlerOptions{Level: slog.LevelDebug}
	baseHandler := slog.NewTextHandler(&buf, opts)
	handler := &redactionHandler{handler: baseHandler}
	logger := slog.New(handler)

	tests := []struct {
		name     string
		msg      string
		attrs    []slog.Attr
		wantNot  string // should not appear in output
		wantHave string // should appear in output
	}{
		{
			name:     "IPv4 in message",
			msg:      "Connecting to server 192.168.1.1:443",
			wantNot:  "192.168.1.1",
			wantHave: "[REDACTED_IP]",
		},
		{
			name:     "IPv4 in attribute",
			msg:      "Server info",
			attrs:    []slog.Attr{slog.String("server", "10.0.0.1:8080")},
			wantNot:  "10.0.0.1",
			wantHave: "[REDACTED_IP]",
		},
		{
			name:     "UUID in message",
			msg:      "Profile b831381d-6324-4d53-ad4f-8cda48b30811 loaded",
			wantNot:  "b831381d-6324-4d53-ad4f-8cda48b30811",
			wantHave: "[REDACTED_UUID]",
		},
		{
			name:     "UUID in attribute", 
			msg:      "Profile loaded",
			attrs:    []slog.Attr{slog.String("uuid", "550e8400-e29b-41d4-a716-446655440000")},
			wantNot:  "550e8400-e29b-41d4-a716-446655440000",
			wantHave: "[REDACTED_UUID]",
		},
		{
			name:     "Normal text unchanged",
			msg:      "Starting VPN connection",
			wantHave: "Starting VPN connection",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			buf.Reset()
			logger.LogAttrs(context.Background(), slog.LevelInfo, tt.msg, tt.attrs...)
			
			output := buf.String()
			
			if tt.wantNot != "" && strings.Contains(output, tt.wantNot) {
				t.Errorf("Output should NOT contain %q, but got:\n%s", tt.wantNot, output)
			}
			
			if tt.wantHave != "" && !strings.Contains(output, tt.wantHave) {
				t.Errorf("Output SHOULD contain %q, but got:\n%s", tt.wantHave, output)
			}
		})
	}
}

func TestIPv4Regex(t *testing.T) {
	tests := []struct {
		ip      string
		matched bool
	}{
		{"192.168.1.1", true},
		{"10.0.0.1", true},
		{"255.255.255.255", true},
		{"0.0.0.0", true},
		{"256.1.1.1", false}, // invalid
		{"192.168.1", false}, // incomplete
		{"text", false},
	}

	for _, tt := range tests {
		t.Run(tt.ip, func(t *testing.T) {
			matched := ipv4Regex.MatchString(tt.ip)
			if matched != tt.matched {
				t.Errorf("ipv4Regex.MatchString(%q) = %v, want %v", tt.ip, matched, tt.matched)
			}
		})
	}
}

func TestUUIDRegex(t *testing.T) {
	tests := []struct {
		uuid    string
		matched bool
	}{
		{"b831381d-6324-4d53-ad4f-8cda48b30811", true},
		{"550e8400-e29b-41d4-a716-446655440000", true},
		{"not-a-uuid", false},
		{"b831381d-6324-4d53-ad4f", false}, // incomplete
	}

	for _, tt := range tests {
		t.Run(tt.uuid, func(t *testing.T) {
			matched := uuidRegex.MatchString(tt.uuid)
			if matched != tt.matched {
				t.Errorf("uuidRegex.MatchString(%q) = %v, want %v", tt.uuid, matched, tt.matched)
			}
		})
	}
}
