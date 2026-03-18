package config

import "fmt"

type ErrorCode string

const (
	ErrUriEmpty             ErrorCode = "ERR_URI_EMPTY"
	ErrUriScheme            ErrorCode = "ERR_URI_SCHEME"
	ErrUriMalformed         ErrorCode = "ERR_URI_MALFORMED"
	ErrUuidInvalid          ErrorCode = "ERR_UUID_INVALID"
	ErrHostMissing          ErrorCode = "ERR_HOST_MISSING"
	ErrPortInvalid          ErrorCode = "ERR_PORT_INVALID"
	ErrParamInvalid         ErrorCode = "ERR_PARAM_INVALID"
	ErrParamUnsupported     ErrorCode = "ERR_PARAM_UNSUPPORTED"
	ErrTlsInvalid           ErrorCode = "ERR_TLS_INVALID"
	ErrProfileUnbuildable   ErrorCode = "ERR_PROFILE_UNBUILDABLE"
)

type ValidationError struct {
	Code    ErrorCode
	Message string
	Err     error
}

func (e *ValidationError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("[%s] %s: %v", e.Code, e.Message, e.Err)
	}
	return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

func NewValidationError(code ErrorCode, msg string, err error) *ValidationError {
	return &ValidationError{Code: code, Message: msg, Err: err}
}
