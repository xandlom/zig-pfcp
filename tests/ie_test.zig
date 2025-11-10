// Comprehensive tests for IE module
const std = @import("std");
const ie = @import("../src/ie.zig");
const types = @import("../src/types.zig");

test "IEHeader - initialization" {
    const header = ie.IEHeader.init(.cause, 1);

    try std.testing.expectEqual(@as(u16, 19), header.ie_type);
    try std.testing.expectEqual(@as(u16, 1), header.length);
}

test "RecoveryTimeStamp - init" {
    const timestamp = ie.RecoveryTimeStamp.init(12345);
    try std.testing.expectEqual(@as(u32, 12345), timestamp.timestamp);
}

test "RecoveryTimeStamp - from Unix time" {
    const unix_time: i64 = 1704067200; // 2024-01-01 00:00:00 UTC
    const timestamp = ie.RecoveryTimeStamp.fromUnixTime(unix_time);

    // NTP offset is 2208988800 seconds
    try std.testing.expectEqual(@as(u32, 3913056000), timestamp.timestamp);
}

test "RecoveryTimeStamp - epoch conversion" {
    const unix_epoch: i64 = 0; // 1970-01-01 00:00:00 UTC
    const timestamp = ie.RecoveryTimeStamp.fromUnixTime(unix_epoch);

    // Should equal NTP offset
    try std.testing.expectEqual(@as(u32, 2208988800), timestamp.timestamp);
}

test "NodeId - IPv4 initialization" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });

    try std.testing.expectEqual(types.NodeIdType.ipv4, node_id.node_id_type);
    try std.testing.expectEqual([_]u8{ 192, 168, 1, 1 }, node_id.value.ipv4);
}

test "NodeId - IPv6 initialization" {
    const addr = [_]u8{ 0x20, 0x01, 0x0d, 0xb8 } ++ [_]u8{0} ** 12;
    const node_id = ie.NodeId.initIpv6(addr);

    try std.testing.expectEqual(types.NodeIdType.ipv6, node_id.node_id_type);
    try std.testing.expectEqual(addr, node_id.value.ipv6);
}

test "NodeId - FQDN initialization" {
    const fqdn = "smf.example.com";
    const node_id = ie.NodeId.initFqdn(fqdn);

    try std.testing.expectEqual(types.NodeIdType.fqdn, node_id.node_id_type);
    try std.testing.expectEqualStrings(fqdn, node_id.value.fqdn);
}

test "FSEID - IPv4 only" {
    const seid: u64 = 0x1234567890ABCDEF;
    const ipv4 = [_]u8{ 10, 0, 0, 1 };
    const fseid = ie.FSEID.initV4(seid, ipv4);

    try std.testing.expectEqual(true, fseid.flags.v4);
    try std.testing.expectEqual(false, fseid.flags.v6);
    try std.testing.expectEqual(seid, fseid.seid);
    try std.testing.expectEqual(ipv4, fseid.ipv4.?);
    try std.testing.expect(fseid.ipv6 == null);
}

test "FSEID - IPv6 only" {
    const seid: u64 = 0x1234567890ABCDEF;
    const ipv6 = [_]u8{ 0x20, 0x01, 0x0d, 0xb8 } ++ [_]u8{0} ** 12;
    const fseid = ie.FSEID.initV6(seid, ipv6);

    try std.testing.expectEqual(false, fseid.flags.v4);
    try std.testing.expectEqual(true, fseid.flags.v6);
    try std.testing.expectEqual(seid, fseid.seid);
    try std.testing.expectEqual(ipv6, fseid.ipv6.?);
    try std.testing.expect(fseid.ipv4 == null);
}

test "FSEID - dual stack" {
    const seid: u64 = 0x1234567890ABCDEF;
    const ipv4 = [_]u8{ 10, 0, 0, 1 };
    const ipv6 = [_]u8{ 0x20, 0x01, 0x0d, 0xb8 } ++ [_]u8{0} ** 12;
    const fseid = ie.FSEID.initDual(seid, ipv4, ipv6);

    try std.testing.expectEqual(true, fseid.flags.v4);
    try std.testing.expectEqual(true, fseid.flags.v6);
    try std.testing.expectEqual(seid, fseid.seid);
    try std.testing.expectEqual(ipv4, fseid.ipv4.?);
    try std.testing.expectEqual(ipv6, fseid.ipv6.?);
}

test "FTEID - IPv4" {
    const teid: u32 = 0x12345678;
    const ipv4 = [_]u8{ 10, 0, 0, 1 };
    const fteid = ie.FTEID.initV4(teid, ipv4);

    try std.testing.expectEqual(true, fteid.flags.v4);
    try std.testing.expectEqual(false, fteid.flags.v6);
    try std.testing.expectEqual(false, fteid.flags.ch);
    try std.testing.expectEqual(teid, fteid.teid);
    try std.testing.expectEqual(ipv4, fteid.ipv4.?);
}

test "FTEID - IPv6" {
    const teid: u32 = 0x12345678;
    const ipv6 = [_]u8{ 0x20, 0x01, 0x0d, 0xb8 } ++ [_]u8{0} ** 12;
    const fteid = ie.FTEID.initV6(teid, ipv6);

    try std.testing.expectEqual(false, fteid.flags.v4);
    try std.testing.expectEqual(true, fteid.flags.v6);
    try std.testing.expectEqual(false, fteid.flags.ch);
    try std.testing.expectEqual(teid, fteid.teid);
    try std.testing.expectEqual(ipv6, fteid.ipv6.?);
}

test "FTEID - CHOOSE flag" {
    const fteid = ie.FTEID.initChoose();

    try std.testing.expectEqual(false, fteid.flags.v4);
    try std.testing.expectEqual(false, fteid.flags.v6);
    try std.testing.expectEqual(true, fteid.flags.ch);
    try std.testing.expectEqual(@as(u32, 0), fteid.teid);
    try std.testing.expect(fteid.ipv4 == null);
    try std.testing.expect(fteid.ipv6 == null);
}

test "UEIPAddress - IPv4 source" {
    const addr = [_]u8{ 192, 168, 1, 100 };
    const ue_ip = ie.UEIPAddress.initIpv4(addr, true);

    try std.testing.expectEqual(true, ue_ip.flags.v4);
    try std.testing.expectEqual(false, ue_ip.flags.v6);
    try std.testing.expectEqual(true, ue_ip.flags.sd);
    try std.testing.expectEqual(addr, ue_ip.ipv4.?);
}

test "UEIPAddress - IPv4 destination" {
    const addr = [_]u8{ 192, 168, 1, 100 };
    const ue_ip = ie.UEIPAddress.initIpv4(addr, false);

    try std.testing.expectEqual(true, ue_ip.flags.v4);
    try std.testing.expectEqual(false, ue_ip.flags.v6);
    try std.testing.expectEqual(false, ue_ip.flags.sd);
}

test "UEIPAddress - IPv6 source" {
    const addr = [_]u8{ 0x20, 0x01, 0x0d, 0xb8 } ++ [_]u8{0} ** 12;
    const ue_ip = ie.UEIPAddress.initIpv6(addr, true);

    try std.testing.expectEqual(false, ue_ip.flags.v4);
    try std.testing.expectEqual(true, ue_ip.flags.v6);
    try std.testing.expectEqual(true, ue_ip.flags.sd);
    try std.testing.expectEqual(addr, ue_ip.ipv6.?);
}

test "PDRID - initialization" {
    const pdr_id = ie.PDRID.init(100);
    try std.testing.expectEqual(@as(u16, 100), pdr_id.rule_id);
}

test "FARID - initialization" {
    const far_id = ie.FARID.init(200);
    try std.testing.expectEqual(@as(u32, 200), far_id.far_id);
}

test "URRID - initialization" {
    const urr_id = ie.URRID.init(300);
    try std.testing.expectEqual(@as(u32, 300), urr_id.urr_id);
}

test "QERID - initialization" {
    const qer_id = ie.QERID.init(400);
    try std.testing.expectEqual(@as(u32, 400), qer_id.qer_id);
}

test "Cause - accepted" {
    const cause = ie.Cause.accepted();
    try std.testing.expectEqual(types.CauseValue.request_accepted, cause.cause);
    try std.testing.expect(cause.cause.isAccepted());
}

test "Cause - rejected" {
    const cause = ie.Cause.init(.request_rejected);
    try std.testing.expectEqual(types.CauseValue.request_rejected, cause.cause);
    try std.testing.expect(!cause.cause.isAccepted());
}

test "Cause - various error codes" {
    const error_causes = [_]types.CauseValue{
        .session_context_not_found,
        .mandatory_ie_missing,
        .system_failure,
        .no_resources_available,
    };

    for (error_causes) |cause_value| {
        const cause = ie.Cause.init(cause_value);
        try std.testing.expect(!cause.cause.isAccepted());
    }
}
