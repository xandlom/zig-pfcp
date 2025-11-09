// zig-pfcp: A Zig implementation of the PFCP protocol (3GPP TS 29.244)
//
// This library provides a comprehensive implementation of the Packet Forwarding
// Control Protocol used in 5G networks for communication between the Control
// Plane (SMF) and User Plane (UPF) functions.

const std = @import("std");

pub const types = @import("types.zig");
pub const ie = @import("ie.zig");
pub const message = @import("message.zig");
pub const marshal = @import("marshal.zig");
pub const util = @import("util.zig");

// Re-export commonly used types
pub const PfcpHeader = types.PfcpHeader;
pub const MessageType = types.MessageType;
pub const NodeIdType = types.NodeIdType;
pub const CauseValue = types.CauseValue;

// Re-export message types
pub const HeartbeatRequest = message.HeartbeatRequest;
pub const HeartbeatResponse = message.HeartbeatResponse;
pub const AssociationSetupRequest = message.AssociationSetupRequest;
pub const AssociationSetupResponse = message.AssociationSetupResponse;
pub const SessionEstablishmentRequest = message.SessionEstablishmentRequest;
pub const SessionEstablishmentResponse = message.SessionEstablishmentResponse;

// Re-export marshaling types
pub const Writer = marshal.Writer;
pub const Reader = marshal.Reader;
pub const MarshalError = marshal.MarshalError;

test {
    std.testing.refAllDecls(@This());
}
