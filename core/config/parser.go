package config

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"net/url"
	"strings"
)

func genID() string {
	b := make([]byte, 8)
	rand.Read(b)
	return fmt.Sprintf("profile-%x", b)
}

// outboundConfig represents VLESS or Hysteria2 outbound configuration
type outboundConfig struct {
	Type       string                 `json:"type"`
	Server     string                 `json:"server"`
	ServerPort int                    `json:"server_port"`
	UUID       string                 `json:"uuid,omitempty"`
	Password   string                 `json:"password,omitempty"`
	TLS        map[string]interface{} `json:"tls,omitempty"`
}

// ParseURI safely cleans, executes strict validation, and constructs a VPN Profile.
func ParseURI(rawUri string) (Profile, error) {
	// Cleans garbage inputs mapped frequently from Whatsapp/Telegram/Clipboards
	rawUri = strings.TrimSpace(rawUri)
	rawUri = strings.ReplaceAll(rawUri, "\n", "")
	rawUri = strings.ReplaceAll(rawUri, "\r", "")

	if rawUri == "" {
		return Profile{}, NewValidationError(ErrUriEmpty, "Input URI is totally empty", nil)
	}

	u, err := url.Parse(rawUri)
	if err != nil {
		return Profile{}, NewValidationError(ErrUriMalformed, "Failed abstract parsing tree", err)
	}

	switch u.Scheme {
	case "vless":
		return parseVLESS(u)
	case "hysteria2", "hy2":
		return parseHysteria2(u)
	default:
		return Profile{}, NewValidationError(ErrUriScheme, "Unsupported protocol scheme drop", nil)
	}
}

func parseVLESS(u *url.URL) (Profile, error) {
	uuid := u.User.Username()
	if err := validateUUID(uuid); err != nil {
		return Profile{}, err
	}

	host := u.Hostname()
	if err := validateHost(host); err != nil {
		return Profile{}, err
	}

	port := u.Port()
	if err := validatePort(port); err != nil {
		return Profile{}, err
	}

	// Security parameter validation (Whitelist fail-closed approach)
	q := u.Query()
	security := q.Get("security")
	if security != "" && security != "tls" && security != "reality" && security != "none" {
		return Profile{}, NewValidationError(ErrTlsInvalid, "Unsupported security bypass: "+security, nil)
	}

	// Strict checks isolating XTLS Reality constraints
	if security == "reality" {
		if q.Get("pbk") == "" {
			return Profile{}, NewValidationError(ErrParamInvalid, "Reality transport strictly requires an explicit server public key (pbk)", nil)
		}
	}

	name := u.Fragment
	name, _ = url.QueryUnescape(name)
	if name == "" {
		name = "VLESS Node"
	}

	// Build safe JSON using struct marshaling
	portInt, _ := parsePortInt(u.Port())
	cfg := outboundConfig{
		Type:       "vless",
		Server:     host,
		ServerPort: portInt,
		UUID:       uuid,
	}
	
	payload, err := json.Marshal(cfg)
	if err != nil {
		return Profile{}, NewValidationError(ErrProfileUnbuildable, "Failed to marshal config", err)
	}

	return Profile{
		ID:   genID(),
		Name: name,
		Endpoint: Endpoint{
			Protocol: "vless",
			Payload:  string(payload),
		},
	}, nil
}

func parseHysteria2(u *url.URL) (Profile, error) {
	password := u.User.Username()
	if password == "" {
		return Profile{}, NewValidationError(ErrParamInvalid, "Hysteria2 auth payload is required", nil)
	}

	host := u.Hostname()
	if err := validateHost(host); err != nil {
		return Profile{}, err
	}

	port := u.Port()
	if err := validatePort(port); err != nil {
		return Profile{}, err
	}
	
	sni := u.Query().Get("sni")
	if sni == "" {
		sni = host
	}

	name := u.Fragment
	name, _ = url.QueryUnescape(name)
	if name == "" {
		name = "HY2 Node"
	}

	// Build safe JSON using struct marshaling
	portInt, _ := parsePortInt(u.Port())
	cfg := outboundConfig{
		Type:       "hysteria2",
		Server:     host,
		ServerPort: portInt,
		Password:   password,
		TLS: map[string]interface{}{
			"server_name": sni,
		},
	}
	
	payload, err := json.Marshal(cfg)
	if err != nil {
		return Profile{}, NewValidationError(ErrProfileUnbuildable, "Failed to marshal config", err)
	}

	return Profile{
		ID:   genID(),
		Name: name,
		Endpoint: Endpoint{
			Protocol: "hysteria2",
			Payload:  string(payload),
		},
	}, nil
}

