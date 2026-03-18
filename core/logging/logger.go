package logging

import (
	"context"
	"log/slog"
	"os"
	"regexp"
)

var Log *slog.Logger

// Regex patterns for IP redaction
var (
	// IPv4 pattern: matches xxx.xxx.xxx.xxx where xxx is 0-255
	ipv4Regex = regexp.MustCompile(`\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b`)
	
	// IPv6 pattern: matches full and compressed IPv6 addresses
	ipv6Regex = regexp.MustCompile(`\b(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\b|\b(?:[0-9a-fA-F]{1,4}:){1,7}:\b|\b(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}\b|\b(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}\b|\b(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}\b|\b(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}\b|\b(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}\b|\b[0-9a-fA-F]{1,4}:(?::[0-9a-fA-F]{1,4}){1,6}\b|\b::(?:[0-9a-fA-F]{1,4}:){0,5}[0-9a-fA-F]{1,4}\b|\b::\b`)
	
	// UUID pattern (VLESS/Hysteria2 user IDs)
	uuidRegex = regexp.MustCompile(`\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b`)
)

// redactionHandler wraps a slog.Handler and redacts sensitive information
type redactionHandler struct {
	handler slog.Handler
}

func (h *redactionHandler) Enabled(ctx context.Context, level slog.Level) bool {
	return h.handler.Enabled(ctx, level)
}

func (h *redactionHandler) Handle(ctx context.Context, r slog.Record) error {
	// Redact sensitive data from message
	msg := r.Message
	msg = ipv4Regex.ReplaceAllString(msg, "[REDACTED_IP]")
	msg = ipv6Regex.ReplaceAllString(msg, "[REDACTED_IP]")
	msg = uuidRegex.ReplaceAllString(msg, "[REDACTED_UUID]")
	r.Message = msg
	
	// Redact sensitive data from attributes
	attrs := []slog.Attr{}
	r.Attrs(func(a slog.Attr) bool {
		// Check string attributes for IPs/UUIDs
		if a.Value.Kind() == slog.KindString {
			val := a.Value.String()
			val = ipv4Regex.ReplaceAllString(val, "[REDACTED_IP]")
			val = ipv6Regex.ReplaceAllString(val, "[REDACTED_IP]")
			val = uuidRegex.ReplaceAllString(val, "[REDACTED_UUID]")
			a.Value = slog.StringValue(val)
		}
		attrs = append(attrs, a)
		return true
	})
	
	// Create new record with redacted attributes
	newRecord := slog.NewRecord(r.Time, r.Level, r.Message, r.PC)
	for _, attr := range attrs {
		newRecord.AddAttrs(attr)
	}
	
	return h.handler.Handle(ctx, newRecord)
}

func (h *redactionHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	return &redactionHandler{handler: h.handler.WithAttrs(attrs)}
}

func (h *redactionHandler) WithGroup(name string) slog.Handler {
	return &redactionHandler{handler: h.handler.WithGroup(name)}
}

func Init() {
	opts := &slog.HandlerOptions{
		Level: slog.LevelDebug,
	}
	
	// Create base handler
	baseHandler := slog.NewTextHandler(os.Stdout, opts)
	
	// Wrap with redaction handler for privacy
	handler := &redactionHandler{handler: baseHandler}
	
	Log = slog.New(handler)
	slog.SetDefault(Log)
}
