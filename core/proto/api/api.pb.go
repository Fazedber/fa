// Code generated manually for NexusVPN compatibility. DO NOT EDIT.
// source: proto/api.proto

package api

import proto "github.com/golang/protobuf/proto"

const _ = proto.ProtoPackageIsVersion4

type ConnectRequest struct {
	ProfileId string `protobuf:"bytes,1,opt,name=profile_id,json=profileId,proto3" json:"profile_id,omitempty"`
}

func (m *ConnectRequest) Reset()         { *m = ConnectRequest{} }
func (m *ConnectRequest) String() string { return proto.CompactTextString(m) }
func (*ConnectRequest) ProtoMessage()    {}
func (*ConnectRequest) Descriptor() ([]byte, []int) {
	return fileDescriptorProtoAPI, []int{0}
}

func (m *ConnectRequest) GetProfileId() string {
	if m != nil {
		return m.ProfileId
	}
	return ""
}

type ConnectResponse struct{}

func (m *ConnectResponse) Reset()         { *m = ConnectResponse{} }
func (m *ConnectResponse) String() string { return proto.CompactTextString(m) }
func (*ConnectResponse) ProtoMessage()    {}
func (*ConnectResponse) Descriptor() ([]byte, []int) {
	return fileDescriptorProtoAPI, []int{1}
}

type DisconnectRequest struct{}

func (m *DisconnectRequest) Reset()         { *m = DisconnectRequest{} }
func (m *DisconnectRequest) String() string { return proto.CompactTextString(m) }
func (*DisconnectRequest) ProtoMessage()    {}
func (*DisconnectRequest) Descriptor() ([]byte, []int) {
	return fileDescriptorProtoAPI, []int{2}
}

type DisconnectResponse struct{}

func (m *DisconnectResponse) Reset()         { *m = DisconnectResponse{} }
func (m *DisconnectResponse) String() string { return proto.CompactTextString(m) }
func (*DisconnectResponse) ProtoMessage()    {}
func (*DisconnectResponse) Descriptor() ([]byte, []int) {
	return fileDescriptorProtoAPI, []int{3}
}

type StateRequest struct{}

func (m *StateRequest) Reset()         { *m = StateRequest{} }
func (m *StateRequest) String() string { return proto.CompactTextString(m) }
func (*StateRequest) ProtoMessage()    {}
func (*StateRequest) Descriptor() ([]byte, []int) {
	return fileDescriptorProtoAPI, []int{4}
}

type StateResponse struct {
	State        string `protobuf:"bytes,1,opt,name=state,proto3" json:"state,omitempty"`
	ErrorMessage string `protobuf:"bytes,2,opt,name=error_message,json=errorMessage,proto3" json:"error_message,omitempty"`
}

func (m *StateResponse) Reset()         { *m = StateResponse{} }
func (m *StateResponse) String() string { return proto.CompactTextString(m) }
func (*StateResponse) ProtoMessage()    {}
func (*StateResponse) Descriptor() ([]byte, []int) {
	return fileDescriptorProtoAPI, []int{5}
}

func (m *StateResponse) GetState() string {
	if m != nil {
		return m.State
	}
	return ""
}

func (m *StateResponse) GetErrorMessage() string {
	if m != nil {
		return m.ErrorMessage
	}
	return ""
}

type StatsRequest struct{}

func (m *StatsRequest) Reset()         { *m = StatsRequest{} }
func (m *StatsRequest) String() string { return proto.CompactTextString(m) }
func (*StatsRequest) ProtoMessage()    {}
func (*StatsRequest) Descriptor() ([]byte, []int) {
	return fileDescriptorProtoAPI, []int{6}
}

type StatsResponse struct {
	UplinkBytes   uint64 `protobuf:"varint,1,opt,name=uplink_bytes,json=uplinkBytes,proto3" json:"uplink_bytes,omitempty"`
	DownlinkBytes uint64 `protobuf:"varint,2,opt,name=downlink_bytes,json=downlinkBytes,proto3" json:"downlink_bytes,omitempty"`
}

func (m *StatsResponse) Reset()         { *m = StatsResponse{} }
func (m *StatsResponse) String() string { return proto.CompactTextString(m) }
func (*StatsResponse) ProtoMessage()    {}
func (*StatsResponse) Descriptor() ([]byte, []int) {
	return fileDescriptorProtoAPI, []int{7}
}

func (m *StatsResponse) GetUplinkBytes() uint64 {
	if m != nil {
		return m.UplinkBytes
	}
	return 0
}

func (m *StatsResponse) GetDownlinkBytes() uint64 {
	if m != nil {
		return m.DownlinkBytes
	}
	return 0
}

type ImportRequest struct {
	Payload string `protobuf:"bytes,1,opt,name=payload,proto3" json:"payload,omitempty"`
}

func (m *ImportRequest) Reset()         { *m = ImportRequest{} }
func (m *ImportRequest) String() string { return proto.CompactTextString(m) }
func (*ImportRequest) ProtoMessage()    {}
func (*ImportRequest) Descriptor() ([]byte, []int) {
	return fileDescriptorProtoAPI, []int{8}
}

func (m *ImportRequest) GetPayload() string {
	if m != nil {
		return m.Payload
	}
	return ""
}

type ImportResponse struct {
	ProfileId string `protobuf:"bytes,1,opt,name=profile_id,json=profileId,proto3" json:"profile_id,omitempty"`
}

func (m *ImportResponse) Reset()         { *m = ImportResponse{} }
func (m *ImportResponse) String() string { return proto.CompactTextString(m) }
func (*ImportResponse) ProtoMessage()    {}
func (*ImportResponse) Descriptor() ([]byte, []int) {
	return fileDescriptorProtoAPI, []int{9}
}

func (m *ImportResponse) GetProfileId() string {
	if m != nil {
		return m.ProfileId
	}
	return ""
}

var fileDescriptorProtoAPI = []byte{}

func init() {
	proto.RegisterType((*ConnectRequest)(nil), "nexusvpn.api.ConnectRequest")
	proto.RegisterType((*ConnectResponse)(nil), "nexusvpn.api.ConnectResponse")
	proto.RegisterType((*DisconnectRequest)(nil), "nexusvpn.api.DisconnectRequest")
	proto.RegisterType((*DisconnectResponse)(nil), "nexusvpn.api.DisconnectResponse")
	proto.RegisterType((*StateRequest)(nil), "nexusvpn.api.StateRequest")
	proto.RegisterType((*StateResponse)(nil), "nexusvpn.api.StateResponse")
	proto.RegisterType((*StatsRequest)(nil), "nexusvpn.api.StatsRequest")
	proto.RegisterType((*StatsResponse)(nil), "nexusvpn.api.StatsResponse")
	proto.RegisterType((*ImportRequest)(nil), "nexusvpn.api.ImportRequest")
	proto.RegisterType((*ImportResponse)(nil), "nexusvpn.api.ImportResponse")
	proto.RegisterFile("proto/api.proto", fileDescriptorProtoAPI)
}
