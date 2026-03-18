// Code generated manually for NexusVPN. DO NOT EDIT.
// source: proto/api.proto

package api

import (
	protoreflect "google.golang.org/protobuf/reflect/protoreflect"
	protoimpl "google.golang.org/protobuf/runtime/protoimpl"
	reflect "reflect"
	sync "sync"
)

const (
	// Verify that this generated code is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(20 - protoimpl.MinVersion)
	// Verify that runtime/protoimpl is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(protoimpl.MaxVersion - 20)
)

type ConnectRequest struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	ProfileId string `protobuf:"bytes,1,opt,name=profile_id,json=profileId,proto3" json:"profile_id,omitempty"`
}

func (x *ConnectRequest) Reset() {
	*x = ConnectRequest{}
}

func (x *ConnectRequest) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*ConnectRequest) ProtoMessage() {}

func (x *ConnectRequest) GetProfileId() string {
	if x != nil {
		return x.ProfileId
	}
	return ""
}

type ConnectResponse struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields
}

func (x *ConnectResponse) Reset() {
	*x = ConnectResponse{}
}

func (x *ConnectResponse) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*ConnectResponse) ProtoMessage() {}

type DisconnectRequest struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields
}

func (x *DisconnectRequest) Reset() {
	*x = DisconnectRequest{}
}

func (x *DisconnectRequest) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*DisconnectRequest) ProtoMessage() {}

type DisconnectResponse struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields
}

func (x *DisconnectResponse) Reset() {
	*x = DisconnectResponse{}
}

func (x *DisconnectResponse) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*DisconnectResponse) ProtoMessage() {}

type StateRequest struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields
}

func (x *StateRequest) Reset() {
	*x = StateRequest{}
}

func (x *StateRequest) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*StateRequest) ProtoMessage() {}

type StateResponse struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	State        string `protobuf:"bytes,1,opt,name=state,proto3" json:"state,omitempty"`
	ErrorMessage string `protobuf:"bytes,2,opt,name=error_message,json=errorMessage,proto3" json:"error_message,omitempty"`
}

func (x *StateResponse) Reset() {
	*x = StateResponse{}
}

func (x *StateResponse) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*StateResponse) ProtoMessage() {}

func (x *StateResponse) GetState() string {
	if x != nil {
		return x.State
	}
	return ""
}

func (x *StateResponse) GetErrorMessage() string {
	if x != nil {
		return x.ErrorMessage
	}
	return ""
}

type StatsRequest struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields
}

func (x *StatsRequest) Reset() {
	*x = StatsRequest{}
}

func (x *StatsRequest) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*StatsRequest) ProtoMessage() {}

type StatsResponse struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	UplinkBytes   uint64 `protobuf:"varint,1,opt,name=uplink_bytes,json=uplinkBytes,proto3" json:"uplink_bytes,omitempty"`
	DownlinkBytes uint64 `protobuf:"varint,2,opt,name=downlink_bytes,json=downlinkBytes,proto3" json:"downlink_bytes,omitempty"`
}

func (x *StatsResponse) Reset() {
	*x = StatsResponse{}
}

func (x *StatsResponse) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*StatsResponse) ProtoMessage() {}

func (x *StatsResponse) GetUplinkBytes() uint64 {
	if x != nil {
		return x.UplinkBytes
	}
	return 0
}

func (x *StatsResponse) GetDownlinkBytes() uint64 {
	if x != nil {
		return x.DownlinkBytes
	}
	return 0
}

type ImportRequest struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Payload string `protobuf:"bytes,1,opt,name=payload,proto3" json:"payload,omitempty"`
}

func (x *ImportRequest) Reset() {
	*x = ImportRequest{}
}

func (x *ImportRequest) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*ImportRequest) ProtoMessage() {}

func (x *ImportRequest) GetPayload() string {
	if x != nil {
		return x.Payload
	}
	return ""
}

type ImportResponse struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	ProfileId string `protobuf:"bytes,1,opt,name=profile_id,json=profileId,proto3" json:"profile_id,omitempty"`
}

func (x *ImportResponse) Reset() {
	*x = ImportResponse{}
}

func (x *ImportResponse) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*ImportResponse) ProtoMessage() {}

func (x *ImportResponse) GetProfileId() string {
	if x != nil {
		return x.ProfileId
	}
	return ""
}

var File_proto_api_proto protoreflect.FileDescriptor

var file_proto_api_proto_rawDesc = []byte{
	// Minimal descriptor for compilation
}

var (
	file_proto_api_proto_goTypes = []interface{}{
		(*ConnectRequest)(nil),
		(*ConnectResponse)(nil),
		(*DisconnectRequest)(nil),
		(*DisconnectResponse)(nil),
		(*StateRequest)(nil),
		(*StateResponse)(nil),
		(*StatsRequest)(nil),
		(*StatsResponse)(nil),
		(*ImportRequest)(nil),
		(*ImportResponse)(nil),
	}
)

func file_proto_api_proto_init() {
	if File_proto_api_proto != nil {
		return
	}
	type x struct{}
	out := protoimpl.TypeBuilder{
		File: protoimpl.DescBuilder{
			GoPackagePath: reflect.TypeOf(x{}).PkgPath(),
			RawDescriptor: file_proto_api_proto_rawDesc,
			NumEnums:      0,
			NumMessages:   10,
			NumExtensions: 0,
			NumServices:   1,
		},
		GoTypes:           file_proto_api_proto_goTypes,
		DependencyIndexes: nil,
	}
	out.File = out.File
	File_proto_api_proto = out.File
}

func init() {
	file_proto_api_proto_init()
}
