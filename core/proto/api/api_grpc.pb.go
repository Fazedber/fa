// Code generated manually for NexusVPN. DO NOT EDIT.
// source: proto/api.proto

package api

import (
	context "context"
	grpc "google.golang.org/grpc"
	codes "google.golang.org/grpc/codes"
	status "google.golang.org/grpc/status"
)

// PlatformBridgeClient is the client API for PlatformBridge service.
type PlatformBridgeClient interface {
	Connect(ctx context.Context, in *ConnectRequest, opts ...grpc.CallOption) (*ConnectResponse, error)
	Disconnect(ctx context.Context, in *DisconnectRequest, opts ...grpc.CallOption) (*DisconnectResponse, error)
	GetState(ctx context.Context, in *StateRequest, opts ...grpc.CallOption) (PlatformBridge_GetStateClient, error)
	GetStats(ctx context.Context, in *StatsRequest, opts ...grpc.CallOption) (PlatformBridge_GetStatsClient, error)
	ImportConfig(ctx context.Context, in *ImportRequest, opts ...grpc.CallOption) (*ImportResponse, error)
}

type platformBridgeClient struct {
	cc grpc.ClientConnInterface
}

func NewPlatformBridgeClient(cc grpc.ClientConnInterface) PlatformBridgeClient {
	return &platformBridgeClient{cc}
}

func (c *platformBridgeClient) Connect(ctx context.Context, in *ConnectRequest, opts ...grpc.CallOption) (*ConnectResponse, error) {
	out := new(ConnectResponse)
	err := c.cc.Invoke(ctx, "/nexusvpn.api.PlatformBridge/Connect", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *platformBridgeClient) Disconnect(ctx context.Context, in *DisconnectRequest, opts ...grpc.CallOption) (*DisconnectResponse, error) {
	out := new(DisconnectResponse)
	err := c.cc.Invoke(ctx, "/nexusvpn.api.PlatformBridge/Disconnect", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *platformBridgeClient) GetState(ctx context.Context, in *StateRequest, opts ...grpc.CallOption) (PlatformBridge_GetStateClient, error) {
	stream, err := c.cc.NewStream(ctx, &PlatformBridge_ServiceDesc.Streams[0], "/nexusvpn.api.PlatformBridge/GetState", opts...)
	if err != nil {
		return nil, err
	}
	x := &platformBridgeGetStateClient{stream}
	if err := x.ClientStream.SendMsg(in); err != nil {
		return nil, err
	}
	if err := x.ClientStream.CloseSend(); err != nil {
		return nil, err
	}
	return x, nil
}

type PlatformBridge_GetStateClient interface {
	Recv() (*StateResponse, error)
	grpc.ClientStream
}

type platformBridgeGetStateClient struct {
	grpc.ClientStream
}

func (x *platformBridgeGetStateClient) Recv() (*StateResponse, error) {
	m := new(StateResponse)
	if err := x.ClientStream.RecvMsg(m); err != nil {
		return nil, err
	}
	return m, nil
}

func (c *platformBridgeClient) GetStats(ctx context.Context, in *StatsRequest, opts ...grpc.CallOption) (PlatformBridge_GetStatsClient, error) {
	stream, err := c.cc.NewStream(ctx, &PlatformBridge_ServiceDesc.Streams[1], "/nexusvpn.api.PlatformBridge/GetStats", opts...)
	if err != nil {
		return nil, err
	}
	x := &platformBridgeGetStatsClient{stream}
	if err := x.ClientStream.SendMsg(in); err != nil {
		return nil, err
	}
	if err := x.ClientStream.CloseSend(); err != nil {
		return nil, err
	}
	return x, nil
}

type PlatformBridge_GetStatsClient interface {
	Recv() (*StatsResponse, error)
	grpc.ClientStream
}

type platformBridgeGetStatsClient struct {
	grpc.ClientStream
}

func (x *platformBridgeGetStatsClient) Recv() (*StatsResponse, error) {
	m := new(StatsResponse)
	if err := x.ClientStream.RecvMsg(m); err != nil {
		return nil, err
	}
	return m, nil
}

func (c *platformBridgeClient) ImportConfig(ctx context.Context, in *ImportRequest, opts ...grpc.CallOption) (*ImportResponse, error) {
	out := new(ImportResponse)
	err := c.cc.Invoke(ctx, "/nexusvpn.api.PlatformBridge/ImportConfig", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// PlatformBridgeServer is the server API for PlatformBridge service.
type PlatformBridgeServer interface {
	Connect(context.Context, *ConnectRequest) (*ConnectResponse, error)
	Disconnect(context.Context, *DisconnectRequest) (*DisconnectResponse, error)
	GetState(*StateRequest, PlatformBridge_GetStateServer) error
	GetStats(*StatsRequest, PlatformBridge_GetStatsServer) error
	ImportConfig(context.Context, *ImportRequest) (*ImportResponse, error)
}

// UnimplementedPlatformBridgeServer must be embedded to have forward compatible implementations.
type UnimplementedPlatformBridgeServer struct {
}

func (UnimplementedPlatformBridgeServer) Connect(context.Context, *ConnectRequest) (*ConnectResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method Connect not implemented")
}

func (UnimplementedPlatformBridgeServer) Disconnect(context.Context, *DisconnectRequest) (*DisconnectResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method Disconnect not implemented")
}

func (UnimplementedPlatformBridgeServer) GetState(*StateRequest, PlatformBridge_GetStateServer) error {
	return status.Errorf(codes.Unimplemented, "method GetState not implemented")
}

func (UnimplementedPlatformBridgeServer) GetStats(*StatsRequest, PlatformBridge_GetStatsServer) error {
	return status.Errorf(codes.Unimplemented, "method GetStats not implemented")
}

func (UnimplementedPlatformBridgeServer) ImportConfig(context.Context, *ImportRequest) (*ImportResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method ImportConfig not implemented")
}

// UnsafePlatformBridgeServer may be embedded to opt out of forward compatibility for this service.
type UnsafePlatformBridgeServer interface {
	mustEmbedUnimplementedPlatformBridgeServer()
}

type PlatformBridge_GetStateServer interface {
	Send(*StateResponse) error
	grpc.ServerStream
}

type PlatformBridge_GetStatsServer interface {
	Send(*StatsResponse) error
	grpc.ServerStream
}

func RegisterPlatformBridgeServer(s grpc.ServiceRegistrar, srv PlatformBridgeServer) {
	s.RegisterService(&PlatformBridge_ServiceDesc, srv)
}

func _PlatformBridge_Connect_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(ConnectRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(PlatformBridgeServer).Connect(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/nexusvpn.api.PlatformBridge/Connect",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(PlatformBridgeServer).Connect(ctx, req.(*ConnectRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _PlatformBridge_Disconnect_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(DisconnectRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(PlatformBridgeServer).Disconnect(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/nexusvpn.api.PlatformBridge/Disconnect",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(PlatformBridgeServer).Disconnect(ctx, req.(*DisconnectRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _PlatformBridge_GetState_Handler(srv interface{}, stream grpc.ServerStream) error {
	m := new(StateRequest)
	if err := stream.RecvMsg(m); err != nil {
		return err
	}
	return srv.(PlatformBridgeServer).GetState(m, &platformBridgeGetStateServer{stream})
}

type PlatformBridge_GetStateServer interface {
	Send(*StateResponse) error
	grpc.ServerStream
}

type platformBridgeGetStateServer struct {
	grpc.ServerStream
}

func (x *platformBridgeGetStateServer) Send(m *StateResponse) error {
	return x.ServerStream.SendMsg(m)
}

func _PlatformBridge_GetStats_Handler(srv interface{}, stream grpc.ServerStream) error {
	m := new(StatsRequest)
	if err := stream.RecvMsg(m); err != nil {
		return err
	}
	return srv.(PlatformBridgeServer).GetStats(m, &platformBridgeGetStatsServer{stream})
}

type PlatformBridge_GetStatsServer interface {
	Send(*StatsResponse) error
	grpc.ServerStream
}

type platformBridgeGetStatsServer struct {
	grpc.ServerStream
}

func (x *platformBridgeGetStatsServer) Send(m *StatsResponse) error {
	return x.ServerStream.SendMsg(m)
}

func _PlatformBridge_ImportConfig_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(ImportRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(PlatformBridgeServer).ImportConfig(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/nexusvpn.api.PlatformBridge/ImportConfig",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(PlatformBridgeServer).ImportConfig(ctx, req.(*ImportRequest))
	}
	return interceptor(ctx, in, info, handler)
}

// PlatformBridge_ServiceDesc is the grpc.ServiceDesc for PlatformBridge service.
var PlatformBridge_ServiceDesc = grpc.ServiceDesc{
	ServiceName: "nexusvpn.api.PlatformBridge",
	HandlerType: (*PlatformBridgeServer)(nil),
	Methods: []grpc.MethodDesc{
		{
			MethodName: "Connect",
			Handler:    _PlatformBridge_Connect_Handler,
		},
		{
			MethodName: "Disconnect",
			Handler:    _PlatformBridge_Disconnect_Handler,
		},
		{
			MethodName: "ImportConfig",
			Handler:    _PlatformBridge_ImportConfig_Handler,
		},
	},
	Streams: []grpc.StreamDesc{
		{
			StreamName:    "GetState",
			Handler:       _PlatformBridge_GetState_Handler,
			ServerStreams: true,
		},
		{
			StreamName:    "GetStats",
			Handler:       _PlatformBridge_GetStats_Handler,
			ServerStreams: true,
		},
	},
	Metadata: "proto/api.proto",
}
