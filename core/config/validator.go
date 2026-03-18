package config

import (
	"regexp"
	"strconv"
)

// RFC 4122 Compliant validation regex
var uuidRegex = regexp.MustCompile(`^(?i)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)

func validateUUID(uid string) error {
	if uid == "" {
		return NewValidationError(ErrUuidInvalid, "UUID is missing from URI", nil)
	}
	if !uuidRegex.MatchString(uid) {
		return NewValidationError(ErrUuidInvalid, "UUID format violates standard schema", nil)
	}
	return nil
}

func validatePort(portStr string) error {
	if portStr == "" {
		return NewValidationError(ErrPortInvalid, "Port segment is missing", nil)
	}
	port, err := strconv.Atoi(portStr)
	if err != nil || port <= 0 || port > 65535 {
		return NewValidationError(ErrPortInvalid, "Port must be bounded strictly between 1 and 65535", nil)
	}
	return nil
}

func validateHost(host string) error {
	if host == "" {
		return NewValidationError(ErrHostMissing, "Hostname or IP resolution segment is completely missing", nil)
	}
	return nil
}

func parsePortInt(portStr string) (int, error) {
	port, err := strconv.Atoi(portStr)
	return port, err
}
