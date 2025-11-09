// Utility functions for PFCP protocol implementation

const std = @import("std");
const types = @import("types.zig");

/// Generate a new sequence number (24-bit)
pub fn generateSequenceNumber() u24 {
    var prng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
    const random = prng.random();
    return @truncate(random.int(u32));
}

/// Convert IPv4 address string to bytes
pub fn parseIpv4(addr: []const u8) ![4]u8 {
    var result: [4]u8 = undefined;
    var iter = std.mem.split(u8, addr, ".");
    var i: usize = 0;

    while (iter.next()) |part| : (i += 1) {
        if (i >= 4) return error.InvalidIpv4;
        result[i] = try std.fmt.parseInt(u8, part, 10);
    }

    if (i != 4) return error.InvalidIpv4;
    return result;
}

/// Convert IPv4 bytes to string
pub fn formatIpv4(addr: [4]u8, buf: []u8) ![]const u8 {
    return try std.fmt.bufPrint(buf, "{d}.{d}.{d}.{d}", .{ addr[0], addr[1], addr[2], addr[3] });
}

/// Convert IPv6 address string to bytes
pub fn parseIpv6(addr: []const u8) ![16]u8 {
    // TODO: Implement full IPv6 parsing
    _ = addr;
    const result: [16]u8 = undefined;
    return result;
}

/// Calculate checksum for PFCP messages
pub fn calculateChecksum(data: []const u8) u16 {
    var sum: u32 = 0;
    var i: usize = 0;

    while (i < data.len - 1) : (i += 2) {
        sum += @as(u32, data[i]) << 8 | @as(u32, data[i + 1]);
    }

    if (i < data.len) {
        sum += @as(u32, data[i]) << 8;
    }

    while (sum >> 16 != 0) {
        sum = (sum & 0xFFFF) + (sum >> 16);
    }

    return @truncate(~sum);
}

/// Endianness conversion helpers
pub fn hton16(value: u16) u16 {
    return std.mem.nativeToBig(u16, value);
}

pub fn hton32(value: u32) u32 {
    return std.mem.nativeToBig(u32, value);
}

pub fn hton64(value: u64) u64 {
    return std.mem.nativeToBig(u64, value);
}

pub fn ntoh16(value: u16) u16 {
    return std.mem.bigToNative(u16, value);
}

pub fn ntoh32(value: u32) u32 {
    return std.mem.bigToNative(u32, value);
}

pub fn ntoh64(value: u64) u64 {
    return std.mem.bigToNative(u64, value);
}

test "IPv4 parsing" {
    const addr = try parseIpv4("192.168.1.1");
    try std.testing.expectEqual([_]u8{ 192, 168, 1, 1 }, addr);
}

test "IPv4 formatting" {
    const addr = [_]u8{ 10, 0, 0, 1 };
    var buf: [16]u8 = undefined;
    const result = try formatIpv4(addr, &buf);
    try std.testing.expectEqualStrings("10.0.0.1", result);
}

test "Sequence number generation" {
    const seq1 = generateSequenceNumber();
    const seq2 = generateSequenceNumber();
    // Just verify they're valid 24-bit values
    try std.testing.expect(seq1 <= 0xFFFFFF);
    try std.testing.expect(seq2 <= 0xFFFFFF);
}

test "Endianness conversion" {
    const val16: u16 = 0x1234;
    const converted = hton16(val16);
    const back = ntoh16(converted);
    try std.testing.expectEqual(val16, back);

    const val32: u32 = 0x12345678;
    const converted32 = hton32(val32);
    const back32 = ntoh32(converted32);
    try std.testing.expectEqual(val32, back32);
}
