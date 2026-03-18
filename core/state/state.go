package state

// ConnectionState represents the tunnel status.
type ConnectionState string

const (
	StateDisconnected   ConnectionState = "DISCONNECTED"
	StateConnecting     ConnectionState = "CONNECTING"
	StateConnected      ConnectionState = "CONNECTED"
	StateReconnecting   ConnectionState = "RECONNECTING"
	StateDisconnecting  ConnectionState = "DISCONNECTING"
	StateFailed         ConnectionState = "FAILED"
)

// StateObserver is implemented by bridges to broadcast to UI.
type StateObserver interface {
	OnStateChanged(newState ConnectionState, err error)
}
