// Performance benchmarks for marshal module
const std = @import("std");
const pfcp = @import("zig-pfcp");
const marshal = pfcp.marshal;

const ITERATIONS = 1_000_000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("PFCP Marshal Performance Benchmarks\n", .{});
    std.debug.print("=====================================\n\n", .{});

    // Benchmark Writer operations
    try benchmarkWriterU8();
    try benchmarkWriterU16();
    try benchmarkWriterU32();
    try benchmarkWriterU64();
    try benchmarkWriterBytes();

    // Benchmark Reader operations
    try benchmarkReaderU8();
    try benchmarkReaderU16();
    try benchmarkReaderU32();
    try benchmarkReaderU64();

    // Benchmark round-trip operations
    try benchmarkRoundTrip(allocator);
}

fn benchmarkWriterU8() !void {
    var buffer: [1024]u8 = undefined;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |i| {
        var writer = marshal.Writer.init(&buffer);
        try writer.writeByte(@truncate(i));
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    std.debug.print("Writer.writeByte:     {} ns/op\n", .{ns_per_op});
}

fn benchmarkWriterU16() !void {
    var buffer: [1024]u8 = undefined;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |i| {
        var writer = marshal.Writer.init(&buffer);
        try writer.writeU16(@truncate(i));
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    std.debug.print("Writer.writeU16:      {} ns/op\n", .{ns_per_op});
}

fn benchmarkWriterU32() !void {
    var buffer: [1024]u8 = undefined;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |i| {
        var writer = marshal.Writer.init(&buffer);
        try writer.writeU32(@truncate(i));
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    std.debug.print("Writer.writeU32:      {} ns/op\n", .{ns_per_op});
}

fn benchmarkWriterU64() !void {
    var buffer: [1024]u8 = undefined;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |i| {
        var writer = marshal.Writer.init(&buffer);
        try writer.writeU64(@intCast(i));
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    std.debug.print("Writer.writeU64:      {} ns/op\n", .{ns_per_op});
}

fn benchmarkWriterBytes() !void {
    var buffer: [1024]u8 = undefined;
    const data = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |_| {
        var writer = marshal.Writer.init(&buffer);
        try writer.writeBytes(&data);
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    std.debug.print("Writer.writeBytes:    {} ns/op (16 bytes)\n", .{ns_per_op});
}

fn benchmarkReaderU8() !void {
    const buffer = [_]u8{0x42} ** 1024;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |_| {
        var reader = marshal.Reader.init(&buffer);
        _ = try reader.readByte();
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    std.debug.print("Reader.readByte:      {} ns/op\n", .{ns_per_op});
}

fn benchmarkReaderU16() !void {
    const buffer = [_]u8{ 0x12, 0x34 } ** 512;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |_| {
        var reader = marshal.Reader.init(&buffer);
        _ = try reader.readU16();
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    std.debug.print("Reader.readU16:       {} ns/op\n", .{ns_per_op});
}

fn benchmarkReaderU32() !void {
    const buffer = [_]u8{ 0x12, 0x34, 0x56, 0x78 } ** 256;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |_| {
        var reader = marshal.Reader.init(&buffer);
        _ = try reader.readU32();
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    std.debug.print("Reader.readU32:       {} ns/op\n", .{ns_per_op});
}

fn benchmarkReaderU64() !void {
    const buffer = [_]u8{ 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0 } ** 128;

    const start = std.time.nanoTimestamp();
    for (0..ITERATIONS) |_| {
        var reader = marshal.Reader.init(&buffer);
        _ = try reader.readU64();
    }
    const end = std.time.nanoTimestamp();

    const ns_per_op = @divFloor(end - start, ITERATIONS);
    std.debug.print("Reader.readU64:       {} ns/op\n", .{ns_per_op});
}

fn benchmarkRoundTrip(allocator: std.mem.Allocator) !void {
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
    std.debug.print("Round-trip (4 ops):   {} ns/op\n", .{ns_per_op});
}
