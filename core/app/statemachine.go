package app

import (
	"sync"
	"nexusvpn/core/state"
)

const maxConcurrentNotifications = 10

type StateMachine struct {
	mu         sync.RWMutex
	current    state.ConnectionState
	observers  []state.StateObserver
	notifySem  chan struct{} // Semaphore to limit concurrent notifications
}

func NewStateMachine() *StateMachine {
	return &StateMachine{
		current:   state.StateDisconnected,
		observers: make([]state.StateObserver, 0),
		notifySem: make(chan struct{}, maxConcurrentNotifications),
	}
}

func (sm *StateMachine) AddObserver(o state.StateObserver) {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	sm.observers = append(sm.observers, o)
}

func (sm *StateMachine) Transition(next state.ConnectionState, err error) {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	sm.current = next
	
	for _, obs := range sm.observers {
		// Use semaphore to limit concurrent notifications
		select {
		case sm.notifySem <- struct{}{}:
			go func(observer state.StateObserver) {
				defer func() { <-sm.notifySem }()
				observer.OnStateChanged(next, err)
			}(obs)
		default:
			// Semaphore full, notify synchronously to prevent goroutine leak
			obs.OnStateChanged(next, err)
		}
	}
}

func (sm *StateMachine) Current() state.ConnectionState {
	sm.mu.RLock()
	defer sm.mu.RUnlock()
	return sm.current
}
