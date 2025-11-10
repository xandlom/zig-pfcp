// Performance benchmarks for marshal module
const std = @import("std");
const marshal = @import("../src/marshal.zig");

const ITERATIONS = 1_000_000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    try stdout.print("PFCP Marshal Performance Benchmarks\n", .{});
    try stdout.print("=====================================\n\n", .{});

    // Benchmark Writer operations
    try benchmarkWriterU8(stdout);
    try benchmarkWriterU16(stdout);
    try benchmarkWriterU32(stdout);
    try benchmarkWriterU64(stdout);
    try benchmarkWriterBytes(stdout);

    // Benchmark Reader operations
    try benchmarkReaderU8(stdout);
    try benchmarkReaderU16(stdout);
    try benchmarkReaderU32(stdout);
    try benchmarkReaderU64(stdout);

    // Benchmark round-trip operations
    try benchmarkRoundTrip(stdout, allocator);
}

fn benchmarkWriterU8(stdout: anytype) !void {
    var buffer: [1024]u8 = undefined;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |i| {
        var writer = marshal.Writer.init(&buffer);
        try writer.writeByte(@truncate(i));
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    try stdout.print("Writer.writeByte:     {} ns/op\n", .{ns_per_op});
}

fn benchmarkWriterU16(stdout: anytype) !void {
    var buffer: [1024]u8 = undefined;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |i| {
        var writer = marshal.Writer.init(&buffer);
        try writer.writeU16(@truncate(i));
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    try stdout.print("Writer.writeU16:      {} ns/op\n", .{ns_per_op});
}

fn benchmarkWriterU32(stdout: anytype) !void {
    var buffer: [1024]u8 = undefined;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |i| {
        var writer = marshal.Writer.init(&buffer);
        try writer.writeU32(@truncate(i));
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    try stdout.print("Writer.writeU32:      {} ns/op\n", .{ns_per_op});
}

fn benchmarkWriterU64(stdout: anytype) !void {
    var buffer: [1024]u8 = undefined;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |i| {
        var writer = marshal.Writer.init(&buffer);
        try writer.writeU64(@intCast(i));
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    try stdout.print("Writer.writeU64:      {} ns/op\n", .{ns_per_op});
}

fn benchmarkWriterBytes(stdout: anytype) !void {
    var buffer: [1024]u8 = undefined;
    const data = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |_| {
        var writer = marshal.Writer.init(&buffer);
        try writer.writeBytes(&data);
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    try stdout.print("Writer.writeBytes:    {} ns/op (16 bytes)\n", .{ns_per_op});
}

fn benchmarkReaderU8(stdout: anytype) !void {
    const buffer = [_]u8{0x42} ** 1024;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |_| {
        var reader = marshal.Reader.init(&buffer);
        _ = try reader.readByte();
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    try stdout.print("Reader.readByte:      {} ns/op\n", .{ns_per_op});
}

fn benchmarkReaderU16(stdout: anytype) !void {
    const buffer = [_]u8{ 0x12, 0x34 } ** 512;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |_| {
        var reader = marshal.Reader.init(&buffer);
        _ = try reader.readU16();
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    try stdout.print("Reader.readU16:       {} ns/op\n", .{ns_per_op});
}

fn benchmarkReaderU32(stdout: anytype) !void {
    const buffer = [_]u8{ 0x12, 0x34, 0x56, 0x78 } ** 256;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |_| {
        var reader = marshal.Reader.init(&buffer);
        _ = try reader.readU32();
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    try stdout.print("Reader.readU32:       {} ns/op\n", .{ns_per_op});
}

fn benchmarkReaderU64(stdout: anytype) !void {
    const buffer = [_]u8{ 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0 } ** 128;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |_| {
        var reader = marshal.Reader.init(&buffer);
        _ = try reader.readU64();
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    try stdout.print("Reader.readU64:       {} ns/op\n", .{ns_per_op});
}

fn benchmarkRoundTrip(stdout: anytype, allocator: std.mem.Allocator) !void {
    _ = allocator;
    var buffer: [1024]u8 = undefined;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |i| {
        var writer = marshal.Writer.init(&buffer);
        try writer.writeByte(@truncate(i));
        try writer.writeU16(@truncate(i));
        try writer.writeU32(@truncate(i));
        try writer.writeU64(@intCast(i));

        const written = writer.getWritten();
        var reader = marshal.Reader.init(written);
        _ = try reader.readByte();
        _ = try reader.readU16();
        _ = try reader.readU32();
        _ = try reader.readU64();
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    try stdout.print("Round-trip (4 ops):   {} ns/op\n", .{ns_per_op});
}
