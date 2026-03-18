package api

import (
	"context"
	"log/slog"
	"time"

	"nexusvpn/core/proto/api"
	"nexusvpn/core/state"
)

// GrpcAdapter implements the gRPC PlatformBridgeServer interface
type GrpcAdapter struct {
	api.UnimplementedPlatformBridgeServer
	server *Server
}

func NewGrpcAdapter(server *Server) *GrpcAdapter {
	return &GrpcAdapter{server: server}
}

func (g *GrpcAdapter) Connect(ctx context.Context, req *api.ConnectRequest) (*api.ConnectResponse, error) {
	slog.Info("gRPC Connect called", "profile_id", req.ProfileId)
	if err := g.server.Connect(ctx, req.ProfileId); err != nil {
		slog.Error("Connect failed", "error", err)
		return nil, err
	}
	return &api.ConnectResponse{}, nil
}

func (g *GrpcAdapter) Disconnect(ctx context.Context, req *api.DisconnectRequest) (*api.DisconnectResponse, error) {
	slog.Info("gRPC Disconnect called")
	if err := g.server.Disconnect(ctx); err != nil {
		slog.Error("Disconnect failed", "error", err)
		return nil, err
	}
	return &api.DisconnectResponse{}, nil
}

func (g *GrpcAdapter) ImportConfig(ctx context.Context, req *api.ImportRequest) (*api.ImportResponse, error) {
	slog.Info("gRPC ImportConfig called")
	profile, err := g.server.ImportConfig(req.Payload)
	if err != nil {
		slog.Error("ImportConfig failed", "error", err)
		return nil, err
	}
	return &api.ImportResponse{ProfileId: profile.ID}, nil
}

// stateObserver adapts state.StateObserver to gRPC streaming
type stateObserver struct {
	stream api.PlatformBridge_GetStateServer
}

func (o *stateObserver) OnStateChanged(newState state.ConnectionState, err error) {
	errMsg := ""
	if err != nil {
		errMsg = err.Error()
	}
	resp := &api.StateResponse{
		State:        string(newState),
		ErrorMessage: errMsg,
	}
	if err := o.stream.Send(resp); err != nil {
		slog.Error("Failed to send state update", "error", err)
	}
}

func (g *GrpcAdapter) GetState(req *api.StateRequest, stream api.PlatformBridge_GetStateServer) error {
	slog.Info("gRPC GetState stream started")
	
	// Send current state immediately
	current := g.server.GetState()
	if err := stream.Send(&api.StateResponse{State: string(current)}); err != nil {
		return err
	}
	
	// Subscribe to state changes
	observer := &stateObserver{stream: stream}
	g.server.SubscribeState(observer)
	
	// Keep stream alive until context is cancelled
	<-stream.Context().Done()
	slog.Info("gRPC GetState stream ended")
	return nil
}

func (g *GrpcAdapter) GetStats(req *api.StatsRequest, stream api.PlatformBridge_GetStatsServer) error {
	slog.Info("gRPC GetStats stream started")
	
	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()
	
	for {
		select {
		case <-stream.Context().Done():
			slog.Info("gRPC GetStats stream ended")
			return nil
		case <-ticker.C:
			stats, err := g.server.GetStats()
			if err != nil {
				// Don't fail on stats error, just skip this tick
				slog.Debug("Failed to get stats", "error", err)
				continue
			}
			resp := &api.StatsResponse{
				UplinkBytes:   stats.UplinkBytes,
				DownlinkBytes: stats.DownlinkBytes,
			}
			if err := stream.Send(resp); err != nil {
				slog.Error("Failed to send stats", "error", err)
				return err
			}
		}
	}
}
