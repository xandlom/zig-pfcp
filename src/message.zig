// PFCP Messages module
// 3GPP TS 29.244 Section 7.4

const std = @import("std");
const types = @import("types.zig");
const ie = @import("ie.zig");

/// Heartbeat Request (3GPP TS 29.244 Section 7.4.4.1)
pub const HeartbeatRequest = struct {
    recovery_time_stamp: ie.RecoveryTimeStamp,

    pub fn init(recovery_time_stamp: ie.RecoveryTimeStamp) HeartbeatRequest {
        return .{ .recovery_time_stamp = recovery_time_stamp };
    }
};

/// Heartbeat Response (3GPP TS 29.244 Section 7.4.4.2)
pub const HeartbeatResponse = struct {
    recovery_time_stamp: ie.RecoveryTimeStamp,

    pub fn init(recovery_time_stamp: ie.RecoveryTimeStamp) HeartbeatResponse {
        return .{ .recovery_time_stamp = recovery_time_stamp };
    }
};

/// Association Setup Request (3GPP TS 29.244 Section 7.4.3.1)
pub const AssociationSetupRequest = struct {
    node_id: ie.NodeId,
    recovery_time_stamp: ie.RecoveryTimeStamp,
    up_function_features: ?u64 = null,
    cp_function_features: ?u64 = null,
    user_plane_ip_resource_information: ?[]const u8 = null,

    pub fn init(node_id: ie.NodeId, recovery_time_stamp: ie.RecoveryTimeStamp) AssociationSetupRequest {
        return .{
            .node_id = node_id,
            .recovery_time_stamp = recovery_time_stamp,
        };
    }
};

/// Association Setup Response (3GPP TS 29.244 Section 7.4.3.2)
pub const AssociationSetupResponse = struct {
    node_id: ie.NodeId,
    cause: ie.Cause,
    recovery_time_stamp: ie.RecoveryTimeStamp,
    up_function_features: ?u64 = null,
    cp_function_features: ?u64 = null,
    user_plane_ip_resource_information: ?[]const u8 = null,

    pub fn init(node_id: ie.NodeId, cause: ie.Cause, recovery_time_stamp: ie.RecoveryTimeStamp) AssociationSetupResponse {
        return .{
            .node_id = node_id,
            .cause = cause,
            .recovery_time_stamp = recovery_time_stamp,
        };
    }

    pub fn accepted(node_id: ie.NodeId, recovery_time_stamp: ie.RecoveryTimeStamp) AssociationSetupResponse {
        return .{
            .node_id = node_id,
            .cause = ie.Cause.accepted(),
            .recovery_time_stamp = recovery_time_stamp,
        };
    }
};

/// Session Establishment Request (3GPP TS 29.244 Section 7.5.2.1)
pub const SessionEstablishmentRequest = struct {
    node_id: ie.NodeId,
    f_seid: ie.FSEID,
    create_pdr: ?[]const u8 = null,
    create_far: ?[]const u8 = null,
    create_urr: ?[]const u8 = null,
    create_qer: ?[]const u8 = null,
    pdn_type: ?u8 = null,

    pub fn init(node_id: ie.NodeId, f_seid: ie.FSEID) SessionEstablishmentRequest {
        return .{
            .node_id = node_id,
            .f_seid = f_seid,
        };
    }
};

/// Session Establishment Response (3GPP TS 29.244 Section 7.5.2.2)
pub const SessionEstablishmentResponse = struct {
    node_id: ie.NodeId,
    cause: ie.Cause,
    f_seid: ?ie.FSEID = null,
    created_pdr: ?[]const u8 = null,
    load_control_information: ?[]const u8 = null,
    overload_control_information: ?[]const u8 = null,

    pub fn init(node_id: ie.NodeId, cause: ie.Cause) SessionEstablishmentResponse {
        return .{
            .node_id = node_id,
            .cause = cause,
        };
    }

    pub fn accepted(node_id: ie.NodeId, f_seid: ie.FSEID) SessionEstablishmentResponse {
        return .{
            .node_id = node_id,
            .cause = ie.Cause.accepted(),
            .f_seid = f_seid,
        };
    }
};

/// Session Modification Request (3GPP TS 29.244 Section 7.5.4.1)
pub const SessionModificationRequest = struct {
    f_seid: ?ie.FSEID = null,
    remove_pdr: ?[]const u8 = null,
    remove_far: ?[]const u8 = null,
    remove_urr: ?[]const u8 = null,
    remove_qer: ?[]const u8 = null,
    create_pdr: ?[]const u8 = null,
    create_far: ?[]const u8 = null,
    create_urr: ?[]const u8 = null,
    create_qer: ?[]const u8 = null,
    update_pdr: ?[]const u8 = null,
    update_far: ?[]const u8 = null,
    update_urr: ?[]const u8 = null,
    update_qer: ?[]const u8 = null,

    pub fn init() SessionModificationRequest {
        return .{};
    }
};

/// Session Modification Response (3GPP TS 29.244 Section 7.5.4.2)
pub const SessionModificationResponse = struct {
    cause: ie.Cause,
    created_pdr: ?[]const u8 = null,
    load_control_information: ?[]const u8 = null,
    overload_control_information: ?[]const u8 = null,
    usage_report: ?[]const u8 = null,

    pub fn init(cause: ie.Cause) SessionModificationResponse {
        return .{ .cause = cause };
    }

    pub fn accepted() SessionModificationResponse {
        return .{ .cause = ie.Cause.accepted() };
    }
};

/// Session Deletion Request (3GPP TS 29.244 Section 7.5.5.1)
pub const SessionDeletionRequest = struct {
    pub fn init() SessionDeletionRequest {
        return .{};
    }
};

/// Session Deletion Response (3GPP TS 29.244 Section 7.5.5.2)
pub const SessionDeletionResponse = struct {
    cause: ie.Cause,
    load_control_information: ?[]const u8 = null,
    overload_control_information: ?[]const u8 = null,
    usage_report: ?[]const u8 = null,

    pub fn init(cause: ie.Cause) SessionDeletionResponse {
        return .{ .cause = cause };
    }

    pub fn accepted() SessionDeletionResponse {
        return .{ .cause = ie.Cause.accepted() };
    }
};

test "Heartbeat message creation" {
    const recovery = ie.RecoveryTimeStamp.init(12345);
    const request = HeartbeatRequest.init(recovery);
    try std.testing.expectEqual(@as(u32, 12345), request.recovery_time_stamp.timestamp);

    const response = HeartbeatResponse.init(recovery);
    try std.testing.expectEqual(@as(u32, 12345), response.recovery_time_stamp.timestamp);
}

test "Association setup response helper" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const recovery = ie.RecoveryTimeStamp.init(12345);

    const response = AssociationSetupResponse.accepted(node_id, recovery);
    try std.testing.expect(response.cause.cause.isAccepted());
}

test "Session establishment response helper" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const fseid = ie.FSEID.initV4(12345, [_]u8{ 10, 0, 0, 1 });

    const response = SessionEstablishmentResponse.accepted(node_id, fseid);
    try std.testing.expect(response.cause.cause.isAccepted());
    try std.testing.expect(response.f_seid != null);
}
