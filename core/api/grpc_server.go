package api

import (
	"context"
	"net"
	"log/slog"
	
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	
	"nexusvpn/core/proto/api"
)

type GrpcAdapter struct {
	coreBridge PlatformBridge
}

// authInterceptor secures localhost IPC by validating the Bearer token
func authInterceptor(expectedToken string) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
		md, ok := metadata.FromIncomingContext(ctx)
		if !ok {
			return nil, status.Errorf(codes.Unauthenticated, "missing metadata")
		}
		
		tokens := md.Get("authorization")
		if len(tokens) == 0 || tokens[0] != "Bearer "+expectedToken {
			slog.Warn("Rejected gRPC request: invalid auth token", "method", info.FullMethod)
			return nil, status.Errorf(codes.Unauthenticated, "invalid token")
		}
		
		return handler(ctx, req)
	}
}

// streamAuthInterceptor validates token for streaming methods
func streamAuthInterceptor(expectedToken string) grpc.StreamServerInterceptor {
	return func(srv interface{}, ss grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
		md, ok := metadata.FromIncomingContext(ss.Context())
		if !ok {
			return status.Errorf(codes.Unauthenticated, "missing metadata")
		}
		
		tokens := md.Get("authorization")
		if len(tokens) == 0 || tokens[0] != "Bearer "+expectedToken {
			slog.Warn("Rejected gRPC stream: invalid auth token", "method", info.FullMethod)
			return status.Errorf(codes.Unauthenticated, "invalid token")
		}
		
		return handler(srv, ss)
	}
}

func ListenAndServeGrpc(server *Server, addr string, token string) error {
	slog.Info("Starting secured gRPC Listening Socket", "addr", addr)
	lis, err := net.Listen("tcp", addr)
	if err != nil {
		slog.Error("Failed to bind port", "error", err)
		return err
	}
	
	grpcServer := grpc.NewServer(
		grpc.UnaryInterceptor(authInterceptor(token)),
		grpc.StreamInterceptor(streamAuthInterceptor(token)),
	)
	
	// Register our gRPC adapter
	adapter := NewGrpcAdapter(server)
	api.RegisterPlatformBridgeServer(grpcServer, adapter)
	
	slog.Info("gRPC Server alive and secured with Localhost Token Authentication")
	return grpcServer.Serve(lis)
}
