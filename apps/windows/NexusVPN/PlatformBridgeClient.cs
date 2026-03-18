using Google.Protobuf;
using Grpc.Core;
using System;
using System.IO;
using System.Threading;

namespace Nexusvpn.Api
{
    public sealed class ConnectRequest
    {
        public string ProfileId { get; set; } = string.Empty;
    }

    public sealed class ConnectResponse
    {
    }

    public sealed class DisconnectRequest
    {
    }

    public sealed class DisconnectResponse
    {
    }

    public sealed class StateRequest
    {
    }

    public sealed class StateResponse
    {
        public string State { get; set; } = string.Empty;
        public string ErrorMessage { get; set; } = string.Empty;
    }

    public sealed class StatsRequest
    {
    }

    public sealed class StatsResponse
    {
        public ulong UplinkBytes { get; set; }
        public ulong DownlinkBytes { get; set; }
    }

    public sealed class ImportRequest
    {
        public string Payload { get; set; } = string.Empty;
    }

    public sealed class ImportResponse
    {
        public string ProfileId { get; set; } = string.Empty;
    }

    internal static class PlatformBridgeProto
    {
        public static byte[] Serialize(ConnectRequest value) =>
            WriteStringField(1, value.ProfileId);

        public static ConnectRequest DeserializeConnectRequest(byte[] data)
        {
            var message = new ConnectRequest();
            ReadFields(data, (tag, input) =>
            {
                switch (tag)
                {
                    case 10:
                        message.ProfileId = input.ReadString();
                        return true;
                    default:
                        return false;
                }
            });
            return message;
        }

        public static byte[] Serialize(ConnectResponse _) => Array.Empty<byte>();
        public static ConnectResponse DeserializeConnectResponse(byte[] _) => new();
        public static byte[] Serialize(DisconnectRequest _) => Array.Empty<byte>();
        public static DisconnectRequest DeserializeDisconnectRequest(byte[] _) => new();
        public static byte[] Serialize(DisconnectResponse _) => Array.Empty<byte>();
        public static DisconnectResponse DeserializeDisconnectResponse(byte[] _) => new();
        public static byte[] Serialize(StateRequest _) => Array.Empty<byte>();
        public static StateRequest DeserializeStateRequest(byte[] _) => new();
        public static byte[] Serialize(StatsRequest _) => Array.Empty<byte>();
        public static StatsRequest DeserializeStatsRequest(byte[] _) => new();

        public static byte[] Serialize(StateResponse value)
        {
            using var stream = new MemoryStream();
            var output = new CodedOutputStream(stream);

            if (!string.IsNullOrEmpty(value.State))
            {
                output.WriteTag(1, WireFormat.WireType.LengthDelimited);
                output.WriteString(value.State);
            }

            if (!string.IsNullOrEmpty(value.ErrorMessage))
            {
                output.WriteTag(2, WireFormat.WireType.LengthDelimited);
                output.WriteString(value.ErrorMessage);
            }

            output.Flush();
            return stream.ToArray();
        }

        public static StateResponse DeserializeStateResponse(byte[] data)
        {
            var message = new StateResponse();
            ReadFields(data, (tag, input) =>
            {
                switch (tag)
                {
                    case 10:
                        message.State = input.ReadString();
                        return true;
                    case 18:
                        message.ErrorMessage = input.ReadString();
                        return true;
                    default:
                        return false;
                }
            });
            return message;
        }

        public static byte[] Serialize(StatsResponse value)
        {
            using var stream = new MemoryStream();
            var output = new CodedOutputStream(stream);

            if (value.UplinkBytes != 0)
            {
                output.WriteTag(1, WireFormat.WireType.Varint);
                output.WriteUInt64(value.UplinkBytes);
            }

            if (value.DownlinkBytes != 0)
            {
                output.WriteTag(2, WireFormat.WireType.Varint);
                output.WriteUInt64(value.DownlinkBytes);
            }

            output.Flush();
            return stream.ToArray();
        }

        public static StatsResponse DeserializeStatsResponse(byte[] data)
        {
            var message = new StatsResponse();
            ReadFields(data, (tag, input) =>
            {
                switch (tag)
                {
                    case 8:
                        message.UplinkBytes = input.ReadUInt64();
                        return true;
                    case 16:
                        message.DownlinkBytes = input.ReadUInt64();
                        return true;
                    default:
                        return false;
                }
            });
            return message;
        }

        public static byte[] Serialize(ImportRequest value) =>
            WriteStringField(1, value.Payload);

        public static ImportRequest DeserializeImportRequest(byte[] data)
        {
            var message = new ImportRequest();
            ReadFields(data, (tag, input) =>
            {
                switch (tag)
                {
                    case 10:
                        message.Payload = input.ReadString();
                        return true;
                    default:
                        return false;
                }
            });
            return message;
        }

        public static byte[] Serialize(ImportResponse value) =>
            WriteStringField(1, value.ProfileId);

        public static ImportResponse DeserializeImportResponse(byte[] data)
        {
            var message = new ImportResponse();
            ReadFields(data, (tag, input) =>
            {
                switch (tag)
                {
                    case 10:
                        message.ProfileId = input.ReadString();
                        return true;
                    default:
                        return false;
                }
            });
            return message;
        }

        private static byte[] WriteStringField(int fieldNumber, string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return Array.Empty<byte>();
            }

            using var stream = new MemoryStream();
            var output = new CodedOutputStream(stream);
            output.WriteTag(fieldNumber, WireFormat.WireType.LengthDelimited);
            output.WriteString(value);
            output.Flush();
            return stream.ToArray();
        }

        private static void ReadFields(byte[] data, Func<uint, CodedInputStream, bool> reader)
        {
            var input = new CodedInputStream(data);
            uint tag;

            while ((tag = input.ReadTag()) != 0)
            {
                if (!reader(tag, input))
                {
                    input.SkipLastField();
                }
            }
        }
    }

    public static class PlatformBridge
    {
        private const string ServiceName = "nexusvpn.api.PlatformBridge";

        private static readonly Marshaller<ConnectRequest> ConnectRequestMarshaller =
            Marshallers.Create(PlatformBridgeProto.Serialize, PlatformBridgeProto.DeserializeConnectRequest);

        private static readonly Marshaller<ConnectResponse> ConnectResponseMarshaller =
            Marshallers.Create(PlatformBridgeProto.Serialize, PlatformBridgeProto.DeserializeConnectResponse);

        private static readonly Marshaller<DisconnectRequest> DisconnectRequestMarshaller =
            Marshallers.Create(PlatformBridgeProto.Serialize, PlatformBridgeProto.DeserializeDisconnectRequest);

        private static readonly Marshaller<DisconnectResponse> DisconnectResponseMarshaller =
            Marshallers.Create(PlatformBridgeProto.Serialize, PlatformBridgeProto.DeserializeDisconnectResponse);

        private static readonly Marshaller<StateRequest> StateRequestMarshaller =
            Marshallers.Create(PlatformBridgeProto.Serialize, PlatformBridgeProto.DeserializeStateRequest);

        private static readonly Marshaller<StateResponse> StateResponseMarshaller =
            Marshallers.Create(PlatformBridgeProto.Serialize, PlatformBridgeProto.DeserializeStateResponse);

        private static readonly Marshaller<StatsRequest> StatsRequestMarshaller =
            Marshallers.Create(PlatformBridgeProto.Serialize, PlatformBridgeProto.DeserializeStatsRequest);

        private static readonly Marshaller<StatsResponse> StatsResponseMarshaller =
            Marshallers.Create(PlatformBridgeProto.Serialize, PlatformBridgeProto.DeserializeStatsResponse);

        private static readonly Marshaller<ImportRequest> ImportRequestMarshaller =
            Marshallers.Create(PlatformBridgeProto.Serialize, PlatformBridgeProto.DeserializeImportRequest);

        private static readonly Marshaller<ImportResponse> ImportResponseMarshaller =
            Marshallers.Create(PlatformBridgeProto.Serialize, PlatformBridgeProto.DeserializeImportResponse);

        private static readonly Method<ConnectRequest, ConnectResponse> ConnectMethod =
            new(MethodType.Unary, ServiceName, "Connect", ConnectRequestMarshaller, ConnectResponseMarshaller);

        private static readonly Method<DisconnectRequest, DisconnectResponse> DisconnectMethod =
            new(MethodType.Unary, ServiceName, "Disconnect", DisconnectRequestMarshaller, DisconnectResponseMarshaller);

        private static readonly Method<StateRequest, StateResponse> GetStateMethod =
            new(MethodType.ServerStreaming, ServiceName, "GetState", StateRequestMarshaller, StateResponseMarshaller);

        private static readonly Method<StatsRequest, StatsResponse> GetStatsMethod =
            new(MethodType.ServerStreaming, ServiceName, "GetStats", StatsRequestMarshaller, StatsResponseMarshaller);

        private static readonly Method<ImportRequest, ImportResponse> ImportConfigMethod =
            new(MethodType.Unary, ServiceName, "ImportConfig", ImportRequestMarshaller, ImportResponseMarshaller);

        public sealed class PlatformBridgeClient
        {
            private readonly CallInvoker _callInvoker;

            public PlatformBridgeClient(ChannelBase channel)
                : this(channel.CreateCallInvoker())
            {
            }

            public PlatformBridgeClient(CallInvoker callInvoker)
            {
                _callInvoker = callInvoker;
            }

            public AsyncUnaryCall<ConnectResponse> ConnectAsync(
                ConnectRequest request,
                Metadata? headers = null,
                DateTime? deadline = null,
                CancellationToken cancellationToken = default) =>
                _callInvoker.AsyncUnaryCall(
                    ConnectMethod,
                    string.Empty,
                    new CallOptions(headers, deadline, cancellationToken),
                    request);

            public AsyncUnaryCall<DisconnectResponse> DisconnectAsync(
                DisconnectRequest request,
                Metadata? headers = null,
                DateTime? deadline = null,
                CancellationToken cancellationToken = default) =>
                _callInvoker.AsyncUnaryCall(
                    DisconnectMethod,
                    string.Empty,
                    new CallOptions(headers, deadline, cancellationToken),
                    request);

            public AsyncServerStreamingCall<StateResponse> GetState(
                StateRequest request,
                Metadata? headers = null,
                DateTime? deadline = null,
                CancellationToken cancellationToken = default) =>
                _callInvoker.AsyncServerStreamingCall(
                    GetStateMethod,
                    string.Empty,
                    new CallOptions(headers, deadline, cancellationToken),
                    request);

            public AsyncServerStreamingCall<StatsResponse> GetStats(
                StatsRequest request,
                Metadata? headers = null,
                DateTime? deadline = null,
                CancellationToken cancellationToken = default) =>
                _callInvoker.AsyncServerStreamingCall(
                    GetStatsMethod,
                    string.Empty,
                    new CallOptions(headers, deadline, cancellationToken),
                    request);

            public AsyncUnaryCall<ImportResponse> ImportConfigAsync(
                ImportRequest request,
                Metadata? headers = null,
                DateTime? deadline = null,
                CancellationToken cancellationToken = default) =>
                _callInvoker.AsyncUnaryCall(
                    ImportConfigMethod,
                    string.Empty,
                    new CallOptions(headers, deadline, cancellationToken),
                    request);
        }
    }
}
