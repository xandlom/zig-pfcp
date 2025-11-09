// Information Elements (IE) module
// 3GPP TS 29.244 Section 8.2

const std = @import("std");
const types = @import("types.zig");

/// Generic IE Header
pub const IEHeader = packed struct {
    ie_type: u16,
    length: u16,

    pub fn init(ie_type: types.IEType, length: u16) IEHeader {
        return .{
            .ie_type = @intFromEnum(ie_type),
            .length = length,
        };
    }
};

/// Recovery Time Stamp IE (3GPP TS 29.244 Section 8.2.5)
pub const RecoveryTimeStamp = struct {
    /// Seconds since 1900-01-01 00:00:00 UTC
    timestamp: u32,

    pub fn init(timestamp: u32) RecoveryTimeStamp {
        return .{ .timestamp = timestamp };
    }

    pub fn fromUnixTime(unix_time: i64) RecoveryTimeStamp {
        // NTP epoch is 1900-01-01, Unix epoch is 1970-01-01
        // Difference is 2208988800 seconds
        const ntp_offset: i64 = 2208988800;
        return .{ .timestamp = @intCast(unix_time + ntp_offset) };
    }
};

/// Node ID IE (3GPP TS 29.244 Section 8.2.38)
pub const NodeId = struct {
    node_id_type: types.NodeIdType,
    value: union(enum) {
        ipv4: [4]u8,
        ipv6: [16]u8,
        fqdn: []const u8,
    },

    pub fn initIpv4(addr: [4]u8) NodeId {
        return .{
            .node_id_type = .ipv4,
            .value = .{ .ipv4 = addr },
        };
    }

    pub fn initIpv6(addr: [16]u8) NodeId {
        return .{
            .node_id_type = .ipv6,
            .value = .{ .ipv6 = addr },
        };
    }

    pub fn initFqdn(fqdn: []const u8) NodeId {
        return .{
            .node_id_type = .fqdn,
            .value = .{ .fqdn = fqdn },
        };
    }
};

/// F-SEID IE (3GPP TS 29.244 Section 8.2.37)
pub const FSEID = struct {
    flags: packed struct {
        v4: bool = false,
        v6: bool = false,
        _spare: u6 = 0,
    },
    seid: u64,
    ipv4: ?[4]u8 = null,
    ipv6: ?[16]u8 = null,

    pub fn initV4(seid: u64, ipv4: [4]u8) FSEID {
        return .{
            .flags = .{ .v4 = true },
            .seid = seid,
            .ipv4 = ipv4,
        };
    }

    pub fn initV6(seid: u64, ipv6: [16]u8) FSEID {
        return .{
            .flags = .{ .v6 = true },
            .seid = seid,
            .ipv6 = ipv6,
        };
    }

    pub fn initDual(seid: u64, ipv4: [4]u8, ipv6: [16]u8) FSEID {
        return .{
            .flags = .{ .v4 = true, .v6 = true },
            .seid = seid,
            .ipv4 = ipv4,
            .ipv6 = ipv6,
        };
    }
};

/// F-TEID IE (3GPP TS 29.244 Section 8.2.3)
pub const FTEID = struct {
    flags: packed struct {
        v4: bool = false,
        v6: bool = false,
        ch: bool = false, // CHOOSE flag
        chid: bool = false, // CHOOSE ID
        _spare: u4 = 0,
    },
    teid: u32,
    ipv4: ?[4]u8 = null,
    ipv6: ?[16]u8 = null,
    choose_id: ?u8 = null,

    pub fn initV4(teid: u32, ipv4: [4]u8) FTEID {
        return .{
            .flags = .{ .v4 = true },
            .teid = teid,
            .ipv4 = ipv4,
        };
    }

    pub fn initV6(teid: u32, ipv6: [16]u8) FTEID {
        return .{
            .flags = .{ .v6 = true },
            .teid = teid,
            .ipv6 = ipv6,
        };
    }

    pub fn initChoose() FTEID {
        return .{
            .flags = .{ .ch = true },
            .teid = 0,
        };
    }
};

/// UE IP Address IE (3GPP TS 29.244 Section 8.2.62)
pub const UEIPAddress = struct {
    flags: packed struct {
        v4: bool = false,
        v6: bool = false,
        sd: bool = false, // Source/Destination
        ipv6d: bool = false, // IPv6 Prefix Delegation
        chv4: bool = false, // CHOOSE IPv4
        chv6: bool = false, // CHOOSE IPv6
        _spare: u2 = 0,
    },
    ipv4: ?[4]u8 = null,
    ipv6: ?[16]u8 = null,
    ipv6_prefix_delegation: ?u8 = null,

    pub fn initIpv4(addr: [4]u8, is_source: bool) UEIPAddress {
        return .{
            .flags = .{ .v4 = true, .sd = is_source },
            .ipv4 = addr,
        };
    }

    pub fn initIpv6(addr: [16]u8, is_source: bool) UEIPAddress {
        return .{
            .flags = .{ .v6 = true, .sd = is_source },
            .ipv6 = addr,
        };
    }
};

/// PDR ID IE (3GPP TS 29.244 Section 8.2.36)
pub const PDRID = struct {
    rule_id: u16,

    pub fn init(rule_id: u16) PDRID {
        return .{ .rule_id = rule_id };
    }
};

/// FAR ID IE (3GPP TS 29.244 Section 8.2.74)
pub const FARID = struct {
    far_id: u32,

    pub fn init(far_id: u32) FARID {
        return .{ .far_id = far_id };
    }
};

/// URR ID IE (3GPP TS 29.244 Section 8.2.35)
pub const URRID = struct {
    urr_id: u32,

    pub fn init(urr_id: u32) URRID {
        return .{ .urr_id = urr_id };
    }
};

/// QER ID IE (3GPP TS 29.244 Section 8.2.123)
pub const QERID = struct {
    qer_id: u32,

    pub fn init(qer_id: u32) QERID {
        return .{ .qer_id = qer_id };
    }
};

/// Precedence IE (3GPP TS 29.244 Section 8.2.11)
pub const Precedence = struct {
    precedence: u32,

    pub fn init(precedence: u32) Precedence {
        return .{ .precedence = precedence };
    }
};

/// Cause IE (3GPP TS 29.244 Section 8.2.1)
pub const Cause = struct {
    cause: types.CauseValue,

    pub fn init(cause: types.CauseValue) Cause {
        return .{ .cause = cause };
    }

    pub fn accepted() Cause {
        return .{ .cause = .request_accepted };
    }

    pub fn rejected() Cause {
        return .{ .cause = .request_rejected };
    }
};

test "Recovery timestamp conversion" {
    const unix_time: i64 = 1609459200; // 2021-01-01 00:00:00 UTC
    const recovery = RecoveryTimeStamp.fromUnixTime(unix_time);
    try std.testing.expect(recovery.timestamp > 0);
}

test "F-SEID initialization" {
    const fseid = FSEID.initV4(12345, [_]u8{ 192, 168, 1, 1 });
    try std.testing.expect(fseid.flags.v4);
    try std.testing.expect(!fseid.flags.v6);
    try std.testing.expectEqual(@as(u64, 12345), fseid.seid);
}

test "F-TEID CHOOSE flag" {
    const fteid = FTEID.initChoose();
    try std.testing.expect(fteid.flags.ch);
    try std.testing.expect(!fteid.flags.v4);
    try std.testing.expect(!fteid.flags.v6);
}
