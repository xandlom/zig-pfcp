// Comprehensive tests for message module
const std = @import("std");
const pfcp = @import("zig-pfcp");
const message = pfcp.message;
const ie = pfcp.ie;
const types = pfcp.types;

test "HeartbeatRequest - initialization" {
    const recovery = ie.RecoveryTimeStamp.init(12345);
    const request = message.HeartbeatRequest.init(recovery);

    try std.testing.expectEqual(@as(u32, 12345), request.recovery_time_stamp.timestamp);
}

test "HeartbeatResponse - initialization" {
    const recovery = ie.RecoveryTimeStamp.init(67890);
    const response = message.HeartbeatResponse.init(recovery);

    try std.testing.expectEqual(@as(u32, 67890), response.recovery_time_stamp.timestamp);
}

test "AssociationSetupRequest - basic initialization" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const recovery = ie.RecoveryTimeStamp.init(12345);
    const request = message.AssociationSetupRequest.init(node_id, recovery);

    try std.testing.expectEqual(types.NodeIdType.ipv4, request.node_id.node_id_type);
    try std.testing.expectEqual(@as(u32, 12345), request.recovery_time_stamp.timestamp);
    try std.testing.expect(request.up_function_features == null);
    try std.testing.expect(request.cp_function_features == null);
}

test "AssociationSetupRequest - with features" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const recovery = ie.RecoveryTimeStamp.init(12345);
    var request = message.AssociationSetupRequest.init(node_id, recovery);

    request.up_function_features = 0x0001;
    request.cp_function_features = 0x0002;

    try std.testing.expectEqual(@as(u64, 0x0001), request.up_function_features.?);
    try std.testing.expectEqual(@as(u64, 0x0002), request.cp_function_features.?);
}

test "AssociationSetupResponse - accepted helper" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 2 });
    const recovery = ie.RecoveryTimeStamp.init(67890);
    const response = message.AssociationSetupResponse.accepted(node_id, recovery);

    try std.testing.expectEqual(types.CauseValue.request_accepted, response.cause.cause);
    try std.testing.expect(response.cause.cause.isAccepted());
    try std.testing.expectEqual(@as(u32, 67890), response.recovery_time_stamp.timestamp);
}

test "AssociationSetupResponse - rejected" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 2 });
    const cause = ie.Cause.init(.system_failure);
    const recovery = ie.RecoveryTimeStamp.init(67890);
    const response = message.AssociationSetupResponse.init(node_id, cause, recovery);

    try std.testing.expectEqual(types.CauseValue.system_failure, response.cause.cause);
    try std.testing.expect(!response.cause.cause.isAccepted());
}

test "SessionEstablishmentRequest - initialization" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 10, 0, 0, 1 });
    const seid: u64 = 0x1234567890ABCDEF;
    const fseid = ie.FSEID.initV4(seid, [_]u8{ 10, 0, 0, 1 });
    const request = message.SessionEstablishmentRequest.init(node_id, fseid);

    try std.testing.expectEqual(types.NodeIdType.ipv4, request.node_id.node_id_type);
    try std.testing.expectEqual(seid, request.f_seid.seid);
    try std.testing.expectEqual(true, request.f_seid.flags.v4);
}

test "SessionEstablishmentRequest - with dual stack F-SEID" {
    const node_id = ie.NodeId.initIpv6([_]u8{0x20} ++ [_]u8{0} ** 15);
    const seid: u64 = 0xFEDCBA0987654321;
    const ipv4 = [_]u8{ 10, 0, 0, 1 };
    const ipv6 = [_]u8{ 0x20, 0x01, 0x0d, 0xb8 } ++ [_]u8{0} ** 12;
    const fseid = ie.FSEID.initDual(seid, ipv4, ipv6);
    const request = message.SessionEstablishmentRequest.init(node_id, fseid);

    try std.testing.expectEqual(true, request.f_seid.flags.v4);
    try std.testing.expectEqual(true, request.f_seid.flags.v6);
}

test "SessionEstablishmentResponse - accepted helper" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 10, 0, 0, 2 });
    const up_seid: u64 = 0xFEDCBA0987654321;
    const up_fseid = ie.FSEID.initV4(up_seid, [_]u8{ 10, 0, 0, 2 });
    const response = message.SessionEstablishmentResponse.accepted(node_id, up_fseid);

    try std.testing.expect(response.cause.cause.isAccepted());
    try std.testing.expect(response.f_seid != null);
    try std.testing.expectEqual(up_seid, response.f_seid.?.seid);
}

test "SessionEstablishmentResponse - rejected without F-SEID" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 10, 0, 0, 2 });
    const cause = ie.Cause.init(.no_resources_available);
    const response = message.SessionEstablishmentResponse.init(node_id, cause);

    try std.testing.expect(!response.cause.cause.isAccepted());
    try std.testing.expect(response.f_seid == null);
}

test "SessionModificationRequest - empty initialization" {
    const request = message.SessionModificationRequest.init();

    try std.testing.expect(request.f_seid == null);
    try std.testing.expect(request.create_pdr == null);
    try std.testing.expect(request.remove_far == null);
}

test "SessionModificationRequest - with F-SEID" {
    var request = message.SessionModificationRequest.init();
    const new_seid: u64 = 0x1111111111111111;
    request.f_seid = ie.FSEID.initV4(new_seid, [_]u8{ 10, 0, 0, 3 });

    try std.testing.expect(request.f_seid != null);
    try std.testing.expectEqual(new_seid, request.f_seid.?.seid);
}

test "SessionModificationResponse - accepted helper" {
    const response = message.SessionModificationResponse.accepted();

    try std.testing.expect(response.cause.cause.isAccepted());
}

test "SessionModificationResponse - rejected" {
    const cause = ie.Cause.init(.rule_creation_modification_failure);
    const response = message.SessionModificationResponse.init(cause);

    try std.testing.expectEqual(types.CauseValue.rule_creation_modification_failure, response.cause.cause);
    try std.testing.expect(!response.cause.cause.isAccepted());
}

test "SessionDeletionRequest - initialization" {
    const request = message.SessionDeletionRequest.init();
    // Just verify it compiles and initializes
    _ = request;
}

test "SessionDeletionResponse - accepted helper" {
    const response = message.SessionDeletionResponse.accepted();

    try std.testing.expect(response.cause.cause.isAccepted());
}

test "SessionDeletionResponse - rejected" {
    const cause = ie.Cause.init(.session_context_not_found);
    const response = message.SessionDeletionResponse.init(cause);

    try std.testing.expectEqual(types.CauseValue.session_context_not_found, response.cause.cause);
    try std.testing.expect(!response.cause.cause.isAccepted());
}

test "Message types - node vs session" {
    // Verify that node messages don't require SEID
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const recovery = ie.RecoveryTimeStamp.init(12345);

    const heartbeat = message.HeartbeatRequest.init(recovery);
    const assoc_req = message.AssociationSetupRequest.init(node_id, recovery);

    // Verify that session messages require SEID
    const seid: u64 = 0x1234567890ABCDEF;
    const fseid = ie.FSEID.initV4(seid, [_]u8{ 10, 0, 0, 1 });

    const session_req = message.SessionEstablishmentRequest.init(node_id, fseid);

    _ = heartbeat;
    _ = assoc_req;
    _ = session_req;
}
