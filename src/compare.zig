// Message Comparison Framework
// Provides utilities for comparing PFCP messages and IEs for testing and validation

const std = @import("std");
const types = @import("types.zig");
const ie = @import("ie.zig");
const message = @import("message.zig");

/// Comparison result
pub const CompareResult = enum {
    equal,
    not_equal,
};

/// Detailed comparison error
pub const CompareError = struct {
    field_name: []const u8,
    expected: []const u8,
    actual: []const u8,

    pub fn format(
        self: CompareError,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Field '{s}': expected={s}, actual={s}", .{
            self.field_name,
            self.expected,
            self.actual,
        });
    }
};

/// Node ID comparison
pub fn compareNodeId(a: ie.NodeId, b: ie.NodeId) CompareResult {
    if (a.node_id_type != b.node_id_type) return .not_equal;

    return switch (a.node_id_type) {
        .ipv4 => if (std.mem.eql(u8, &a.value.ipv4, &b.value.ipv4)) .equal else .not_equal,
        .ipv6 => if (std.mem.eql(u8, &a.value.ipv6, &b.value.ipv6)) .equal else .not_equal,
        .fqdn => if (std.mem.eql(u8, a.value.fqdn, b.value.fqdn)) .equal else .not_equal,
        _ => .not_equal,
    };
}

/// F-SEID comparison
pub fn compareFSEID(a: ie.FSEID, b: ie.FSEID) CompareResult {
    if (a.seid != b.seid) return .not_equal;
    if (a.flags.v4 != b.flags.v4) return .not_equal;
    if (a.flags.v6 != b.flags.v6) return .not_equal;

    if (a.flags.v4) {
        if (a.ipv4 == null or b.ipv4 == null) return .not_equal;
        if (!std.mem.eql(u8, &a.ipv4.?, &b.ipv4.?)) return .not_equal;
    }

    if (a.flags.v6) {
        if (a.ipv6 == null or b.ipv6 == null) return .not_equal;
        if (!std.mem.eql(u8, &a.ipv6.?, &b.ipv6.?)) return .not_equal;
    }

    return .equal;
}

/// F-TEID comparison
pub fn compareFTEID(a: ie.FTEID, b: ie.FTEID) CompareResult {
    if (a.teid != b.teid) return .not_equal;
    if (a.flags.v4 != b.flags.v4) return .not_equal;
    if (a.flags.v6 != b.flags.v6) return .not_equal;
    if (a.flags.ch != b.flags.ch) return .not_equal;

    if (a.flags.v4) {
        if (a.ipv4 == null or b.ipv4 == null) return .not_equal;
        if (!std.mem.eql(u8, &a.ipv4.?, &b.ipv4.?)) return .not_equal;
    }

    if (a.flags.v6) {
        if (a.ipv6 == null or b.ipv6 == null) return .not_equal;
        if (!std.mem.eql(u8, &a.ipv6.?, &b.ipv6.?)) return .not_equal;
    }

    return .equal;
}

/// UE IP Address comparison
pub fn compareUEIPAddress(a: ie.UEIPAddress, b: ie.UEIPAddress) CompareResult {
    if (a.flags.v4 != b.flags.v4) return .not_equal;
    if (a.flags.v6 != b.flags.v6) return .not_equal;
    if (a.flags.sd != b.flags.sd) return .not_equal;

    if (a.flags.v4) {
        if (a.ipv4 == null or b.ipv4 == null) return .not_equal;
        if (!std.mem.eql(u8, &a.ipv4.?, &b.ipv4.?)) return .not_equal;
    }

    if (a.flags.v6) {
        if (a.ipv6 == null or b.ipv6 == null) return .not_equal;
        if (!std.mem.eql(u8, &a.ipv6.?, &b.ipv6.?)) return .not_equal;
    }

    return .equal;
}

/// Cause comparison
pub fn compareCause(a: ie.Cause, b: ie.Cause) CompareResult {
    return if (a.cause == b.cause) .equal else .not_equal;
}

/// Recovery Time Stamp comparison
pub fn compareRecoveryTimeStamp(a: ie.RecoveryTimeStamp, b: ie.RecoveryTimeStamp) CompareResult {
    return if (a.timestamp == b.timestamp) .equal else .not_equal;
}

/// Heartbeat Request comparison
pub fn compareHeartbeatRequest(a: message.HeartbeatRequest, b: message.HeartbeatRequest) CompareResult {
    return compareRecoveryTimeStamp(a.recovery_time_stamp, b.recovery_time_stamp);
}

/// Heartbeat Response comparison
pub fn compareHeartbeatResponse(a: message.HeartbeatResponse, b: message.HeartbeatResponse) CompareResult {
    return compareRecoveryTimeStamp(a.recovery_time_stamp, b.recovery_time_stamp);
}

/// Association Setup Request comparison
pub fn compareAssociationSetupRequest(a: message.AssociationSetupRequest, b: message.AssociationSetupRequest) CompareResult {
    if (compareNodeId(a.node_id, b.node_id) != .equal) return .not_equal;
    if (compareRecoveryTimeStamp(a.recovery_time_stamp, b.recovery_time_stamp) != .equal) return .not_equal;

    // Compare optional fields
    if ((a.up_function_features == null) != (b.up_function_features == null)) return .not_equal;
    if (a.up_function_features) |a_val| {
        if (b.up_function_features) |b_val| {
            if (a_val != b_val) return .not_equal;
        }
    }

    if ((a.cp_function_features == null) != (b.cp_function_features == null)) return .not_equal;
    if (a.cp_function_features) |a_val| {
        if (b.cp_function_features) |b_val| {
            if (a_val != b_val) return .not_equal;
        }
    }

    return .equal;
}

/// Association Setup Response comparison
pub fn compareAssociationSetupResponse(a: message.AssociationSetupResponse, b: message.AssociationSetupResponse) CompareResult {
    if (compareNodeId(a.node_id, b.node_id) != .equal) return .not_equal;
    if (compareCause(a.cause, b.cause) != .equal) return .not_equal;
    if (compareRecoveryTimeStamp(a.recovery_time_stamp, b.recovery_time_stamp) != .equal) return .not_equal;

    return .equal;
}

/// Session Establishment Request comparison
pub fn compareSessionEstablishmentRequest(a: message.SessionEstablishmentRequest, b: message.SessionEstablishmentRequest) CompareResult {
    if (compareNodeId(a.node_id, b.node_id) != .equal) return .not_equal;
    if (compareFSEID(a.f_seid, b.f_seid) != .equal) return .not_equal;

    return .equal;
}

/// Session Establishment Response comparison
pub fn compareSessionEstablishmentResponse(a: message.SessionEstablishmentResponse, b: message.SessionEstablishmentResponse) CompareResult {
    if (compareNodeId(a.node_id, b.node_id) != .equal) return .not_equal;
    if (compareCause(a.cause, b.cause) != .equal) return .not_equal;

    // Compare optional F-SEID
    if ((a.f_seid == null) != (b.f_seid == null)) return .not_equal;
    if (a.f_seid) |a_val| {
        if (b.f_seid) |b_val| {
            if (compareFSEID(a_val, b_val) != .equal) return .not_equal;
        }
    }

    return .equal;
}

/// Binary data comparison utility
pub fn compareBinaryData(a: []const u8, b: []const u8) CompareResult {
    return if (std.mem.eql(u8, a, b)) .equal else .not_equal;
}

/// Print comparison difference to stderr for debugging
pub fn printDifference(comptime T: type, field_name: []const u8, a: T, b: T) void {
    const stderr = std.io.getStdErr().writer();
    stderr.print("Difference in field '{s}':\n", .{field_name}) catch {};
    stderr.print("  Expected: {any}\n", .{a}) catch {};
    stderr.print("  Actual:   {any}\n", .{b}) catch {};
}

test "compareNodeId - equal IPv4" {
    const node1 = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const node2 = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });

    try std.testing.expectEqual(CompareResult.equal, compareNodeId(node1, node2));
}

test "compareNodeId - different IPv4" {
    const node1 = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const node2 = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 2 });

    try std.testing.expectEqual(CompareResult.not_equal, compareNodeId(node1, node2));
}

test "compareFSEID - equal" {
    const fseid1 = ie.FSEID.initV4(0x1234567890ABCDEF, [_]u8{ 10, 0, 0, 1 });
    const fseid2 = ie.FSEID.initV4(0x1234567890ABCDEF, [_]u8{ 10, 0, 0, 1 });

    try std.testing.expectEqual(CompareResult.equal, compareFSEID(fseid1, fseid2));
}

test "compareFSEID - different SEID" {
    const fseid1 = ie.FSEID.initV4(0x1234567890ABCDEF, [_]u8{ 10, 0, 0, 1 });
    const fseid2 = ie.FSEID.initV4(0xFEDCBA0987654321, [_]u8{ 10, 0, 0, 1 });

    try std.testing.expectEqual(CompareResult.not_equal, compareFSEID(fseid1, fseid2));
}

test "compareHeartbeatRequest - equal" {
    const recovery = ie.RecoveryTimeStamp.init(12345);
    const req1 = message.HeartbeatRequest.init(recovery);
    const req2 = message.HeartbeatRequest.init(recovery);

    try std.testing.expectEqual(CompareResult.equal, compareHeartbeatRequest(req1, req2));
}

test "compareBinaryData - equal" {
    const data1 = [_]u8{ 0x01, 0x02, 0x03, 0x04 };
    const data2 = [_]u8{ 0x01, 0x02, 0x03, 0x04 };

    try std.testing.expectEqual(CompareResult.equal, compareBinaryData(&data1, &data2));
}

test "compareBinaryData - different" {
    const data1 = [_]u8{ 0x01, 0x02, 0x03, 0x04 };
    const data2 = [_]u8{ 0x01, 0x02, 0x03, 0x05 };

    try std.testing.expectEqual(CompareResult.not_equal, compareBinaryData(&data1, &data2));
}
