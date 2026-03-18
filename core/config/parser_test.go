package config

import (
	"testing"
)

func TestParseURI_Table(t *testing.T) {
	tests := []struct {
		name        string
		uri         string
		expectError ErrorCode
	}{
		{"Valid VLESS TLS", "vless://b831381d-6324-4d53-ad4f-8cda48b30811@192.168.1.1:443?security=tls#JapanNode", ""},
		{"Valid VLESS Reality", "vless://b831381d-6324-4d53-ad4f-8cda48b30811@192.168.1.1:443?security=reality&pbk=asdfasdf#JapanNode", ""},
		{"Valid HY2", "hysteria2://pass123@example.com:8443?sni=example.com#HyNode", ""},
		{"Empty string dirty", "   \n  \r  ", ErrUriEmpty},
		{"Unknown scheme fallback", "vmess://uuid@host:123", ErrUriScheme},
		{"Invalid UUID syntax", "vless://bad-uuid-totally-wrong@server.com:443", ErrUuidInvalid},
		{"Missing Host block", "vless://b831381d-6324-4d53-ad4f-8cda48b30811@:443", ErrHostMissing},
		{"Missing Port block", "vless://b831381d-6324-4d53-ad4f-8cda48b30811@host", ErrPortInvalid},
		{"Port out of range overflow", "vless://b831381d-6324-4d53-ad4f-8cda48b30811@host:99999", ErrPortInvalid},
		{"Invalid Security string fail-closed", "vless://b831381d-6324-4d53-ad4f-8cda48b30811@host:443?security=faketls", ErrTlsInvalid},
		{"Reality missing pbk validation context", "vless://b831381d-6324-4d53-ad4f-8cda48b30811@host:443?security=reality", ErrParamInvalid},
		{"Percent Encoded Label sanitization", "vless://b831381d-6324-4d53-ad4f-8cda48b30811@host:443#My%20Node", ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := ParseURI(tt.uri)
			if tt.expectError == "" {
				if err != nil {
					t.Fatalf("Expected strictly no error, got %v", err)
				}
			} else {
				if err == nil {
					t.Fatalf("Expected error code execution blocking, got nil allowed bypass")
				}
				valErr, ok := err.(*ValidationError)
				if !ok {
					t.Fatalf("Expected mapped typed ValidationError, got abstract %T", err)
				}
				if valErr.Code != tt.expectError {
					t.Fatalf("Expected exact error code %s but caught -> %s", tt.expectError, valErr.Code)
				}
			}
		})
	}
}
