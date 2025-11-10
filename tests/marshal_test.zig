// Comprehensive tests for marshal module
const std = @import("std");
const pfcp = @import("zig-pfcp");
const marshal = pfcp.marshal;

test "Writer - initialization" {
    var buffer: [1024]u8 = undefined;
    const writer = marshal.Writer.init(&buffer);

    try std.testing.expectEqual(@as(usize, 0), writer.pos);
    try std.testing.expectEqual(@as(usize, 1024), writer.remaining());
}

test "Writer - writeByte" {
    var buffer: [10]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    try writer.writeByte(0x42);
    try std.testing.expectEqual(@as(u8, 0x42), buffer[0]);
    try std.testing.expectEqual(@as(usize, 1), writer.pos);
}

test "Writer - writeByte buffer overflow" {
    var buffer: [1]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    try writer.writeByte(0x42);
    try std.testing.expectError(marshal.MarshalError.BufferTooSmall, writer.writeByte(0x43));
}

test "Writer - writeU16" {
    var buffer: [10]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    try writer.writeU16(0x1234);
    try std.testing.expectEqual(@as(u8, 0x12), buffer[0]);
    try std.testing.expectEqual(@as(u8, 0x34), buffer[1]);
    try std.testing.expectEqual(@as(usize, 2), writer.pos);
}

test "Writer - writeU16 big-endian" {
    var buffer: [10]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    try writer.writeU16(0xABCD);
    const value = std.mem.readInt(u16, buffer[0..2], .big);
    try std.testing.expectEqual(@as(u16, 0xABCD), value);
}

test "Writer - writeU24" {
    var buffer: [10]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    try writer.writeU24(0x123456);
    try std.testing.expectEqual(@as(u8, 0x12), buffer[0]);
    try std.testing.expectEqual(@as(u8, 0x34), buffer[1]);
    try std.testing.expectEqual(@as(u8, 0x56), buffer[2]);
    try std.testing.expectEqual(@as(usize, 3), writer.pos);
}

test "Writer - writeU32" {
    var buffer: [10]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    try writer.writeU32(0x12345678);
    try std.testing.expectEqual(@as(u8, 0x12), buffer[0]);
    try std.testing.expectEqual(@as(u8, 0x34), buffer[1]);
    try std.testing.expectEqual(@as(u8, 0x56), buffer[2]);
    try std.testing.expectEqual(@as(u8, 0x78), buffer[3]);
}

test "Writer - writeU64" {
    var buffer: [10]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    try writer.writeU64(0x123456789ABCDEF0);
    const value = std.mem.readInt(u64, buffer[0..8], .big);
    try std.testing.expectEqual(@as(u64, 0x123456789ABCDEF0), value);
    try std.testing.expectEqual(@as(usize, 8), writer.pos);
}

test "Writer - writeBytes" {
    var buffer: [10]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    const data = [_]u8{ 0x11, 0x22, 0x33, 0x44 };
    try writer.writeBytes(&data);
    try std.testing.expectEqual(data[0], buffer[0]);
    try std.testing.expectEqual(data[1], buffer[1]);
    try std.testing.expectEqual(data[2], buffer[2]);
    try std.testing.expectEqual(data[3], buffer[3]);
    try std.testing.expectEqual(@as(usize, 4), writer.pos);
}

test "Writer - skip" {
    var buffer: [10]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    try writer.skip(5);
    try std.testing.expectEqual(@as(usize, 5), writer.pos);
    try std.testing.expectEqual(@as(usize, 5), writer.remaining());
}

test "Writer - getWritten" {
    var buffer: [10]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    try writer.writeByte(0x42);
    try writer.writeU16(0x1234);
    const written = writer.getWritten();

    try std.testing.expectEqual(@as(usize, 3), written.len);
    try std.testing.expectEqual(@as(u8, 0x42), written[0]);
    try std.testing.expectEqual(@as(u8, 0x12), written[1]);
    try std.testing.expectEqual(@as(u8, 0x34), written[2]);
}

test "Writer - sequential writes" {
    var buffer: [100]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    try writer.writeByte(0x01);
    try writer.writeU16(0x0203);
    try writer.writeU32(0x04050607);
    try writer.writeU64(0x08090A0B0C0D0E0F);

    try std.testing.expectEqual(@as(usize, 1 + 2 + 4 + 8), writer.pos);
}

test "Reader - initialization" {
    const buffer = [_]u8{ 0x01, 0x02, 0x03 };
    const reader = marshal.Reader.init(&buffer);

    try std.testing.expectEqual(@as(usize, 0), reader.pos);
    try std.testing.expectEqual(@as(usize, 3), reader.remaining());
}

test "Reader - readByte" {
    const buffer = [_]u8{ 0x42, 0x43 };
    var reader = marshal.Reader.init(&buffer);

    const value = try reader.readByte();
    try std.testing.expectEqual(@as(u8, 0x42), value);
    try std.testing.expectEqual(@as(usize, 1), reader.pos);
}

test "Reader - readByte underflow" {
    const buffer = [_]u8{0x42};
    var reader = marshal.Reader.init(&buffer);

    _ = try reader.readByte();
    try std.testing.expectError(marshal.MarshalError.InvalidLength, reader.readByte());
}

test "Reader - readU16" {
    const buffer = [_]u8{ 0x12, 0x34, 0x56 };
    var reader = marshal.Reader.init(&buffer);

    const value = try reader.readU16();
    try std.testing.expectEqual(@as(u16, 0x1234), value);
    try std.testing.expectEqual(@as(usize, 2), reader.pos);
}

test "Reader - readU24" {
    const buffer = [_]u8{ 0x12, 0x34, 0x56, 0x78 };
    var reader = marshal.Reader.init(&buffer);

    const value = try reader.readU24();
    try std.testing.expectEqual(@as(u24, 0x123456), value);
    try std.testing.expectEqual(@as(usize, 3), reader.pos);
}

test "Reader - readU32" {
    const buffer = [_]u8{ 0x12, 0x34, 0x56, 0x78, 0x9A };
    var reader = marshal.Reader.init(&buffer);

    const value = try reader.readU32();
    try std.testing.expectEqual(@as(u32, 0x12345678), value);
    try std.testing.expectEqual(@as(usize, 4), reader.pos);
}

test "Reader - readU64" {
    const buffer = [_]u8{ 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0, 0xFF };
    var reader = marshal.Reader.init(&buffer);

    const value = try reader.readU64();
    try std.testing.expectEqual(@as(u64, 0x123456789ABCDEF0), value);
    try std.testing.expectEqual(@as(usize, 8), reader.pos);
}

test "Reader - readBytes" {
    const buffer = [_]u8{ 0x11, 0x22, 0x33, 0x44, 0x55 };
    var reader = marshal.Reader.init(&buffer);

    const bytes = try reader.readBytes(3);
    try std.testing.expectEqual(@as(usize, 3), bytes.len);
    try std.testing.expectEqual(@as(u8, 0x11), bytes[0]);
    try std.testing.expectEqual(@as(u8, 0x22), bytes[1]);
    try std.testing.expectEqual(@as(u8, 0x33), bytes[2]);
    try std.testing.expectEqual(@as(usize, 3), reader.pos);
}

test "Reader - skip" {
    const buffer = [_]u8{ 0x11, 0x22, 0x33, 0x44, 0x55 };
    var reader = marshal.Reader.init(&buffer);

    try reader.skip(3);
    try std.testing.expectEqual(@as(usize, 3), reader.pos);
    const value = try reader.readByte();
    try std.testing.expectEqual(@as(u8, 0x44), value);
}

test "Reader - peek" {
    const buffer = [_]u8{ 0x11, 0x22, 0x33 };
    const reader = marshal.Reader.init(&buffer);

    const value = try reader.peek(1);
    try std.testing.expectEqual(@as(u8, 0x22), value);
    try std.testing.expectEqual(@as(usize, 0), reader.pos);
}

test "Reader - sequential reads" {
    const buffer = [_]u8{ 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F };
    var reader = marshal.Reader.init(&buffer);

    const b = try reader.readByte();
    const val_u16 = try reader.readU16();
    const val_u32 = try reader.readU32();
    const val_u64 = try reader.readU64();

    try std.testing.expectEqual(@as(u8, 0x01), b);
    try std.testing.expectEqual(@as(u16, 0x0203), val_u16);
    try std.testing.expectEqual(@as(u32, 0x04050607), val_u32);
    try std.testing.expectEqual(@as(u64, 0x08090A0B0C0D0E0F), val_u64);
}

test "Writer and Reader - round trip" {
    var buffer: [100]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    // Write data
    try writer.writeByte(0x42);
    try writer.writeU16(0x1234);
    try writer.writeU32(0x56789ABC);
    try writer.writeU64(0xDEADBEEFCAFEBABE);

    // Read back
    const written = writer.getWritten();
    var reader = marshal.Reader.init(written);

    const b = try reader.readByte();
    const val_u16 = try reader.readU16();
    const val_u32 = try reader.readU32();
    const val_u64 = try reader.readU64();

    try std.testing.expectEqual(@as(u8, 0x42), b);
    try std.testing.expectEqual(@as(u16, 0x1234), val_u16);
    try std.testing.expectEqual(@as(u32, 0x56789ABC), val_u32);
    try std.testing.expectEqual(@as(u64, 0xDEADBEEFCAFEBABE), val_u64);
}

test "MarshalError - all error types defined" {
    const errors = [_]marshal.MarshalError{
        marshal.MarshalError.BufferTooSmall,
        marshal.MarshalError.InvalidLength,
        marshal.MarshalError.InvalidVersion,
        marshal.MarshalError.InvalidMessageType,
        marshal.MarshalError.InvalidIEType,
        marshal.MarshalError.MissingMandatoryIE,
        marshal.MarshalError.OutOfMemory,
    };
    _ = errors;
}
