// PFCP Message Marshaling/Unmarshaling module
// Handles encoding and decoding of PFCP messages to/from binary format
// 3GPP TS 29.244

const std = @import("std");
const types = @import("types.zig");
const ie = @import("ie.zig");
const message = @import("message.zig");

/// Marshaling errors
pub const MarshalError = error{
    BufferTooSmall,
    InvalidLength,
    InvalidVersion,
    InvalidMessageType,
    InvalidIEType,
    MissingMandatoryIE,
    OutOfMemory,
};

/// Writer for encoding PFCP data to binary format
pub const Writer = struct {
    buffer: []u8,
    pos: usize,

    pub fn init(buffer: []u8) Writer {
        return .{ .buffer = buffer, .pos = 0 };
    }

    pub fn remaining(self: *const Writer) usize {
        return self.buffer.len - self.pos;
    }

    pub fn writeByte(self: *Writer, value: u8) MarshalError!void {
        if (self.pos >= self.buffer.len) return MarshalError.BufferTooSmall;
        self.buffer[self.pos] = value;
        self.pos += 1;
    }

    pub fn writeU16(self: *Writer, value: u16) MarshalError!void {
        if (self.remaining() < 2) return MarshalError.BufferTooSmall;
        std.mem.writeInt(u16, self.buffer[self.pos..][0..2], value, .big);
        self.pos += 2;
    }

    pub fn writeU24(self: *Writer, value: u24) MarshalError!void {
        if (self.remaining() < 3) return MarshalError.BufferTooSmall;
        // Write 24-bit value in big-endian
        self.buffer[self.pos] = @truncate(value >> 16);
        self.buffer[self.pos + 1] = @truncate(value >> 8);
        self.buffer[self.pos + 2] = @truncate(value);
        self.pos += 3;
    }

    pub fn writeU32(self: *Writer, value: u32) MarshalError!void {
        if (self.remaining() < 4) return MarshalError.BufferTooSmall;
        std.mem.writeInt(u32, self.buffer[self.pos..][0..4], value, .big);
        self.pos += 4;
    }

    pub fn writeU64(self: *Writer, value: u64) MarshalError!void {
        if (self.remaining() < 8) return MarshalError.BufferTooSmall;
        std.mem.writeInt(u64, self.buffer[self.pos..][0..8], value, .big);
        self.pos += 8;
    }

    pub fn writeBytes(self: *Writer, bytes: []const u8) MarshalError!void {
        if (self.remaining() < bytes.len) return MarshalError.BufferTooSmall;
        @memcpy(self.buffer[self.pos..][0..bytes.len], bytes);
        self.pos += bytes.len;
    }

    pub fn skip(self: *Writer, n: usize) MarshalError!void {
        if (self.remaining() < n) return MarshalError.BufferTooSmall;
        self.pos += n;
    }

    pub fn getWritten(self: *const Writer) []const u8 {
        return self.buffer[0..self.pos];
    }
};

/// Reader for decoding PFCP data from binary format
pub const Reader = struct {
    buffer: []const u8,
    pos: usize,

    pub fn init(buffer: []const u8) Reader {
        return .{ .buffer = buffer, .pos = 0 };
    }

    pub fn remaining(self: *const Reader) usize {
        return self.buffer.len - self.pos;
    }

    pub fn readByte(self: *Reader) MarshalError!u8 {
        if (self.pos >= self.buffer.len) return MarshalError.InvalidLength;
        const value = self.buffer[self.pos];
        self.pos += 1;
        return value;
    }

    pub fn readU16(self: *Reader) MarshalError!u16 {
        if (self.remaining() < 2) return MarshalError.InvalidLength;
        const value = std.mem.readInt(u16, self.buffer[self.pos..][0..2], .big);
        self.pos += 2;
        return value;
    }

    pub fn readU24(self: *Reader) MarshalError!u24 {
        if (self.remaining() < 3) return MarshalError.InvalidLength;
        // Read 24-bit value in big-endian
        const b0: u24 = self.buffer[self.pos];
        const b1: u24 = self.buffer[self.pos + 1];
        const b2: u24 = self.buffer[self.pos + 2];
        const value: u24 = (b0 << 16) | (b1 << 8) | b2;
        self.pos += 3;
        return value;
    }

    pub fn readU32(self: *Reader) MarshalError!u32 {
        if (self.remaining() < 4) return MarshalError.InvalidLength;
        const value = std.mem.readInt(u32, self.buffer[self.pos..][0..4], .big);
        self.pos += 4;
        return value;
    }

    pub fn readU64(self: *Reader) MarshalError!u64 {
        if (self.remaining() < 8) return MarshalError.InvalidLength;
        const value = std.mem.readInt(u64, self.buffer[self.pos..][0..8], .big);
        self.pos += 8;
        return value;
    }

    pub fn readBytes(self: *Reader, n: usize) MarshalError![]const u8 {
        if (self.remaining() < n) return MarshalError.InvalidLength;
        const bytes = self.buffer[self.pos..][0..n];
        self.pos += n;
        return bytes;
    }

    pub fn skip(self: *Reader, n: usize) MarshalError!void {
        if (self.remaining() < n) return MarshalError.InvalidLength;
        self.pos += n;
    }

    pub fn peek(self: *const Reader, offset: usize) MarshalError!u8 {
        if (self.pos + offset >= self.buffer.len) return MarshalError.InvalidLength;
        return self.buffer[self.pos + offset];
    }
};

/// Encode PFCP header to binary format
pub fn encodePfcpHeader(writer: *Writer, header: types.PfcpHeader) MarshalError!void {
    // Byte 0: Version (4 bits) + Spare (2 bits) + MP (1 bit) + S (1 bit)
    var byte0: u8 = 0;
    byte0 |= (@as(u8, header.version) << 5);
    byte0 |= (@as(u8, @intFromBool(header.mp)) << 1);
    byte0 |= @as(u8, @intFromBool(header.s));
    try writer.writeByte(byte0);

    // Byte 1: Message Type
    try writer.writeByte(header.message_type);

    // Bytes 2-3: Message Length (big-endian)
    try writer.writeU16(header.message_length);

    // SEID if present (8 bytes)
    if (header.s) {
        try writer.writeU64(header.seid orelse 0);
    }

    // Sequence Number (3 bytes)
    try writer.writeU24(header.sequence_number);

    // Spare (1 byte)
    try writer.writeByte(header.spare3);
}

/// Decode PFCP header from binary format
pub fn decodePfcpHeader(reader: *Reader) MarshalError!types.PfcpHeader {
    // Byte 0: Version + flags
    const byte0 = try reader.readByte();
    const version: u4 = @truncate(byte0 >> 5);
    const mp = (byte0 & 0x02) != 0;
    const s = (byte0 & 0x01) != 0;

    if (version != types.PFCP_VERSION) {
        return MarshalError.InvalidVersion;
    }

    // Byte 1: Message Type
    const message_type = try reader.readByte();

    // Bytes 2-3: Message Length
    const message_length = try reader.readU16();

    // SEID if present
    var seid: ?u64 = null;
    if (s) {
        seid = try reader.readU64();
    }

    // Sequence Number
    const sequence_number = try reader.readU24();

    // Spare
    const spare3 = try reader.readByte();

    return types.PfcpHeader{
        .version = version,
        .mp = mp,
        .s = s,
        .message_type = message_type,
        .message_length = message_length,
        .seid = seid,
        .sequence_number = sequence_number,
        .spare3 = spare3,
    };
}

/// Encode IE header (Type + Length)
pub fn encodeIEHeader(writer: *Writer, ie_type: types.IEType, length: u16) MarshalError!void {
    try writer.writeU16(@intFromEnum(ie_type));
    try writer.writeU16(length);
}

/// Decode IE header
pub fn decodeIEHeader(reader: *Reader) MarshalError!ie.IEHeader {
    const ie_type = try reader.readU16();
    const length = try reader.readU16();
    return ie.IEHeader{
        .ie_type = ie_type,
        .length = length,
    };
}

/// Encode Recovery Time Stamp IE
pub fn encodeRecoveryTimeStamp(writer: *Writer, rts: ie.RecoveryTimeStamp) MarshalError!void {
    try encodeIEHeader(writer, .recovery_time_stamp, 4);
    try writer.writeU32(rts.timestamp);
}

/// Decode Recovery Time Stamp IE
pub fn decodeRecoveryTimeStamp(reader: *Reader, length: u16) MarshalError!ie.RecoveryTimeStamp {
    if (length != 4) return MarshalError.InvalidLength;
    const timestamp = try reader.readU32();
    return ie.RecoveryTimeStamp{ .timestamp = timestamp };
}

/// Encode Node ID IE
pub fn encodeNodeId(writer: *Writer, node_id: ie.NodeId) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve space for header

    // Encode node ID type and value
    const type_byte: u8 = @intFromEnum(node_id.node_id_type);
    try writer.writeByte(type_byte);

    switch (node_id.value) {
        .ipv4 => |addr| try writer.writeBytes(&addr),
        .ipv6 => |addr| try writer.writeBytes(&addr),
        .fqdn => |fqdn| try writer.writeBytes(fqdn),
    }

    // Calculate and write header
    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .node_id, ie_length);
    writer.pos = saved_pos;
}

/// Decode Node ID IE
pub fn decodeNodeId(reader: *Reader, length: u16, allocator: std.mem.Allocator) MarshalError!ie.NodeId {
    if (length < 1) return MarshalError.InvalidLength;

    const type_byte = try reader.readByte();
    const node_id_type: types.NodeIdType = @enumFromInt(@as(u4, @truncate(type_byte)));
    const value_length = length - 1;

    switch (node_id_type) {
        .ipv4 => {
            if (value_length != 4) return MarshalError.InvalidLength;
            const addr_bytes = try reader.readBytes(4);
            var addr: [4]u8 = undefined;
            @memcpy(&addr, addr_bytes);
            return ie.NodeId.initIpv4(addr);
        },
        .ipv6 => {
            if (value_length != 16) return MarshalError.InvalidLength;
            const addr_bytes = try reader.readBytes(16);
            var addr: [16]u8 = undefined;
            @memcpy(&addr, addr_bytes);
            return ie.NodeId.initIpv6(addr);
        },
        .fqdn => {
            const fqdn_bytes = try reader.readBytes(value_length);
            const fqdn = try allocator.dupe(u8, fqdn_bytes);
            return ie.NodeId.initFqdn(fqdn);
        },
        _ => return MarshalError.InvalidIEType,
    }
}

/// Encode F-SEID IE
pub fn encodeFSEID(writer: *Writer, fseid: ie.FSEID) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve space for header

    // Encode flags
    var flags: u8 = 0;
    if (fseid.flags.v4) flags |= 0x02;
    if (fseid.flags.v6) flags |= 0x01;
    try writer.writeByte(flags);

    // Encode SEID
    try writer.writeU64(fseid.seid);

    // Encode IP addresses
    if (fseid.ipv4) |addr| {
        try writer.writeBytes(&addr);
    }
    if (fseid.ipv6) |addr| {
        try writer.writeBytes(&addr);
    }

    // Calculate and write header
    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .f_seid, ie_length);
    writer.pos = saved_pos;
}

/// Decode F-SEID IE
pub fn decodeFSEID(reader: *Reader, length: u16) MarshalError!ie.FSEID {
    if (length < 9) return MarshalError.InvalidLength; // At least flags + SEID

    const flags_byte = try reader.readByte();
    const v4 = (flags_byte & 0x02) != 0;
    const v6 = (flags_byte & 0x01) != 0;

    const seid = try reader.readU64();

    var ipv4: ?[4]u8 = null;
    var ipv6: ?[16]u8 = null;

    if (v4) {
        const addr_bytes = try reader.readBytes(4);
        var addr: [4]u8 = undefined;
        @memcpy(&addr, addr_bytes);
        ipv4 = addr;
    }

    if (v6) {
        const addr_bytes = try reader.readBytes(16);
        var addr: [16]u8 = undefined;
        @memcpy(&addr, addr_bytes);
        ipv6 = addr;
    }

    return ie.FSEID{
        .flags = .{ .v4 = v4, .v6 = v6 },
        .seid = seid,
        .ipv4 = ipv4,
        .ipv6 = ipv6,
    };
}

/// Encode F-TEID IE
pub fn encodeFTEID(writer: *Writer, fteid: ie.FTEID) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve space for header

    // Encode flags
    var flags: u8 = 0;
    if (fteid.flags.v4) flags |= 0x08;
    if (fteid.flags.v6) flags |= 0x04;
    if (fteid.flags.ch) flags |= 0x02;
    if (fteid.flags.chid) flags |= 0x01;
    try writer.writeByte(flags);

    // Encode TEID
    try writer.writeU32(fteid.teid);

    // Encode IP addresses
    if (fteid.ipv4) |addr| {
        try writer.writeBytes(&addr);
    }
    if (fteid.ipv6) |addr| {
        try writer.writeBytes(&addr);
    }

    // Encode CHOOSE ID
    if (fteid.choose_id) |choose_id| {
        try writer.writeByte(choose_id);
    }

    // Calculate and write header
    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .f_teid, ie_length);
    writer.pos = saved_pos;
}

/// Decode F-TEID IE
pub fn decodeFTEID(reader: *Reader, length: u16) MarshalError!ie.FTEID {
    if (length < 5) return MarshalError.InvalidLength; // At least flags + TEID

    const flags_byte = try reader.readByte();
    const v4 = (flags_byte & 0x08) != 0;
    const v6 = (flags_byte & 0x04) != 0;
    const ch = (flags_byte & 0x02) != 0;
    const chid = (flags_byte & 0x01) != 0;

    const teid = try reader.readU32();

    var ipv4: ?[4]u8 = null;
    var ipv6: ?[16]u8 = null;
    var choose_id: ?u8 = null;

    if (v4) {
        const addr_bytes = try reader.readBytes(4);
        var addr: [4]u8 = undefined;
        @memcpy(&addr, addr_bytes);
        ipv4 = addr;
    }

    if (v6) {
        const addr_bytes = try reader.readBytes(16);
        var addr: [16]u8 = undefined;
        @memcpy(&addr, addr_bytes);
        ipv6 = addr;
    }

    if (chid) {
        choose_id = try reader.readByte();
    }

    return ie.FTEID{
        .flags = .{ .v4 = v4, .v6 = v6, .ch = ch, .chid = chid },
        .teid = teid,
        .ipv4 = ipv4,
        .ipv6 = ipv6,
        .choose_id = choose_id,
    };
}

/// Encode Cause IE
pub fn encodeCause(writer: *Writer, cause: ie.Cause) MarshalError!void {
    try encodeIEHeader(writer, .cause, 1);
    try writer.writeByte(@intFromEnum(cause.cause));
}

/// Decode Cause IE
pub fn decodeCause(reader: *Reader, length: u16) MarshalError!ie.Cause {
    if (length != 1) return MarshalError.InvalidLength;
    const cause_value = try reader.readByte();
    return ie.Cause{ .cause = @enumFromInt(cause_value) };
}

/// Encode UE IP Address IE
pub fn encodeUEIPAddress(writer: *Writer, ue_ip: ie.UEIPAddress) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve space for header

    // Encode flags
    var flags: u8 = 0;
    if (ue_ip.flags.v4) flags |= 0x80;
    if (ue_ip.flags.v6) flags |= 0x40;
    if (ue_ip.flags.sd) flags |= 0x20;
    if (ue_ip.flags.ipv6d) flags |= 0x10;
    if (ue_ip.flags.chv4) flags |= 0x08;
    if (ue_ip.flags.chv6) flags |= 0x04;
    try writer.writeByte(flags);

    // Encode IP addresses
    if (ue_ip.ipv4) |addr| {
        try writer.writeBytes(&addr);
    }
    if (ue_ip.ipv6) |addr| {
        try writer.writeBytes(&addr);
    }

    // Encode IPv6 prefix delegation
    if (ue_ip.ipv6_prefix_delegation) |prefix| {
        try writer.writeByte(prefix);
    }

    // Calculate and write header
    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .ue_ip_address, ie_length);
    writer.pos = saved_pos;
}

/// Decode UE IP Address IE
pub fn decodeUEIPAddress(reader: *Reader, length: u16) MarshalError!ie.UEIPAddress {
    if (length < 1) return MarshalError.InvalidLength;

    const flags_byte = try reader.readByte();
    const v4 = (flags_byte & 0x80) != 0;
    const v6 = (flags_byte & 0x40) != 0;
    const sd = (flags_byte & 0x20) != 0;
    const ipv6d = (flags_byte & 0x10) != 0;
    const chv4 = (flags_byte & 0x08) != 0;
    const chv6 = (flags_byte & 0x04) != 0;

    var ipv4: ?[4]u8 = null;
    var ipv6: ?[16]u8 = null;
    var ipv6_prefix_delegation: ?u8 = null;

    if (v4) {
        const addr_bytes = try reader.readBytes(4);
        var addr: [4]u8 = undefined;
        @memcpy(&addr, addr_bytes);
        ipv4 = addr;
    }

    if (v6) {
        const addr_bytes = try reader.readBytes(16);
        var addr: [16]u8 = undefined;
        @memcpy(&addr, addr_bytes);
        ipv6 = addr;
    }

    if (ipv6d) {
        ipv6_prefix_delegation = try reader.readByte();
    }

    return ie.UEIPAddress{
        .flags = .{ .v4 = v4, .v6 = v6, .sd = sd, .ipv6d = ipv6d, .chv4 = chv4, .chv6 = chv6 },
        .ipv4 = ipv4,
        .ipv6 = ipv6,
        .ipv6_prefix_delegation = ipv6_prefix_delegation,
    };
}

/// Encode Heartbeat Request message
pub fn encodeHeartbeatRequest(writer: *Writer, req: message.HeartbeatRequest, sequence_number: u24) MarshalError!void {
    const header_start = writer.pos;

    // Reserve space for header
    var header = types.PfcpHeader.init(.heartbeat_request, false);
    header.sequence_number = sequence_number;
    try encodePfcpHeader(writer, header);

    // Encode IEs
    try encodeRecoveryTimeStamp(writer, req.recovery_time_stamp);

    // Calculate message length (total - header size)
    const message_length: u16 = @intCast(writer.pos - header_start - 4);

    // Update header with correct length
    const saved_pos = writer.pos;
    writer.pos = header_start + 2;
    try writer.writeU16(message_length);
    writer.pos = saved_pos;
}

/// Encode Heartbeat Response message
pub fn encodeHeartbeatResponse(writer: *Writer, resp: message.HeartbeatResponse, sequence_number: u24) MarshalError!void {
    const header_start = writer.pos;

    // Reserve space for header
    var header = types.PfcpHeader.init(.heartbeat_response, false);
    header.sequence_number = sequence_number;
    try encodePfcpHeader(writer, header);

    // Encode IEs
    try encodeRecoveryTimeStamp(writer, resp.recovery_time_stamp);

    // Calculate message length
    const message_length: u16 = @intCast(writer.pos - header_start - 4);

    // Update header with correct length
    const saved_pos = writer.pos;
    writer.pos = header_start + 2;
    try writer.writeU16(message_length);
    writer.pos = saved_pos;
}

/// Encode Association Setup Request message
pub fn encodeAssociationSetupRequest(writer: *Writer, req: message.AssociationSetupRequest, sequence_number: u24) MarshalError!void {
    const header_start = writer.pos;

    var header = types.PfcpHeader.init(.association_setup_request, false);
    header.sequence_number = sequence_number;
    try encodePfcpHeader(writer, header);

    // Encode mandatory IEs
    try encodeNodeId(writer, req.node_id);
    try encodeRecoveryTimeStamp(writer, req.recovery_time_stamp);

    // Calculate message length
    const message_length: u16 = @intCast(writer.pos - header_start - 4);
    const saved_pos = writer.pos;
    writer.pos = header_start + 2;
    try writer.writeU16(message_length);
    writer.pos = saved_pos;
}

/// Encode Association Setup Response message
pub fn encodeAssociationSetupResponse(writer: *Writer, resp: message.AssociationSetupResponse, sequence_number: u24) MarshalError!void {
    const header_start = writer.pos;

    var header = types.PfcpHeader.init(.association_setup_response, false);
    header.sequence_number = sequence_number;
    try encodePfcpHeader(writer, header);

    // Encode mandatory IEs
    try encodeNodeId(writer, resp.node_id);
    try encodeCause(writer, resp.cause);
    try encodeRecoveryTimeStamp(writer, resp.recovery_time_stamp);

    // Calculate message length
    const message_length: u16 = @intCast(writer.pos - header_start - 4);
    const saved_pos = writer.pos;
    writer.pos = header_start + 2;
    try writer.writeU16(message_length);
    writer.pos = saved_pos;
}

/// Encode Session Establishment Request message
pub fn encodeSessionEstablishmentRequest(writer: *Writer, req: message.SessionEstablishmentRequest, seid: u64, sequence_number: u24) MarshalError!void {
    const header_start = writer.pos;

    var header = types.PfcpHeader.init(.session_establishment_request, true);
    header.seid = seid;
    header.sequence_number = sequence_number;
    try encodePfcpHeader(writer, header);

    // Encode mandatory IEs
    try encodeNodeId(writer, req.node_id);
    try encodeFSEID(writer, req.f_seid);

    // Calculate message length
    const message_length: u16 = @intCast(writer.pos - header_start - 4);
    const saved_pos = writer.pos;
    writer.pos = header_start + 2;
    try writer.writeU16(message_length);
    writer.pos = saved_pos;
}

/// Encode Session Establishment Response message
pub fn encodeSessionEstablishmentResponse(writer: *Writer, resp: message.SessionEstablishmentResponse, seid: u64, sequence_number: u24) MarshalError!void {
    const header_start = writer.pos;

    var header = types.PfcpHeader.init(.session_establishment_response, true);
    header.seid = seid;
    header.sequence_number = sequence_number;
    try encodePfcpHeader(writer, header);

    // Encode mandatory IEs
    try encodeNodeId(writer, resp.node_id);
    try encodeCause(writer, resp.cause);

    // Encode optional F-SEID
    if (resp.f_seid) |fseid| {
        try encodeFSEID(writer, fseid);
    }

    // Calculate message length
    const message_length: u16 = @intCast(writer.pos - header_start - 4);
    const saved_pos = writer.pos;
    writer.pos = header_start + 2;
    try writer.writeU16(message_length);
    writer.pos = saved_pos;
}

/// Decode Heartbeat Request message
pub fn decodeHeartbeatRequest(reader: *Reader, allocator: std.mem.Allocator) MarshalError!message.HeartbeatRequest {
    _ = allocator;
    var recovery_time_stamp: ?ie.RecoveryTimeStamp = null;

    while (reader.remaining() > 0) {
        const ie_header = try decodeIEHeader(reader);
        const ie_type: types.IEType = @enumFromInt(ie_header.ie_type);

        switch (ie_type) {
            .recovery_time_stamp => {
                recovery_time_stamp = try decodeRecoveryTimeStamp(reader, ie_header.length);
            },
            else => {
                // Skip unknown IE
                try reader.skip(ie_header.length);
            },
        }
    }

    if (recovery_time_stamp == null) {
        return MarshalError.MissingMandatoryIE;
    }

    return message.HeartbeatRequest.init(recovery_time_stamp.?);
}

/// Decode Heartbeat Response message
pub fn decodeHeartbeatResponse(reader: *Reader, allocator: std.mem.Allocator) MarshalError!message.HeartbeatResponse {
    _ = allocator;
    var recovery_time_stamp: ?ie.RecoveryTimeStamp = null;

    while (reader.remaining() > 0) {
        const ie_header = try decodeIEHeader(reader);
        const ie_type: types.IEType = @enumFromInt(ie_header.ie_type);

        switch (ie_type) {
            .recovery_time_stamp => {
                recovery_time_stamp = try decodeRecoveryTimeStamp(reader, ie_header.length);
            },
            else => {
                try reader.skip(ie_header.length);
            },
        }
    }

    if (recovery_time_stamp == null) {
        return MarshalError.MissingMandatoryIE;
    }

    return message.HeartbeatResponse.init(recovery_time_stamp.?);
}

/// Decode Association Setup Request message
pub fn decodeAssociationSetupRequest(reader: *Reader, allocator: std.mem.Allocator) MarshalError!message.AssociationSetupRequest {
    var node_id: ?ie.NodeId = null;
    var recovery_time_stamp: ?ie.RecoveryTimeStamp = null;

    while (reader.remaining() > 0) {
        const ie_header = try decodeIEHeader(reader);
        const ie_type: types.IEType = @enumFromInt(ie_header.ie_type);

        switch (ie_type) {
            .node_id => {
                node_id = try decodeNodeId(reader, ie_header.length, allocator);
            },
            .recovery_time_stamp => {
                recovery_time_stamp = try decodeRecoveryTimeStamp(reader, ie_header.length);
            },
            else => {
                try reader.skip(ie_header.length);
            },
        }
    }

    if (node_id == null or recovery_time_stamp == null) {
        return MarshalError.MissingMandatoryIE;
    }

    return message.AssociationSetupRequest.init(node_id.?, recovery_time_stamp.?);
}

/// Decode Association Setup Response message
pub fn decodeAssociationSetupResponse(reader: *Reader, allocator: std.mem.Allocator) MarshalError!message.AssociationSetupResponse {
    var node_id: ?ie.NodeId = null;
    var cause: ?ie.Cause = null;
    var recovery_time_stamp: ?ie.RecoveryTimeStamp = null;

    while (reader.remaining() > 0) {
        const ie_header = try decodeIEHeader(reader);
        const ie_type: types.IEType = @enumFromInt(ie_header.ie_type);

        switch (ie_type) {
            .node_id => {
                node_id = try decodeNodeId(reader, ie_header.length, allocator);
            },
            .cause => {
                cause = try decodeCause(reader, ie_header.length);
            },
            .recovery_time_stamp => {
                recovery_time_stamp = try decodeRecoveryTimeStamp(reader, ie_header.length);
            },
            else => {
                try reader.skip(ie_header.length);
            },
        }
    }

    if (node_id == null or cause == null or recovery_time_stamp == null) {
        return MarshalError.MissingMandatoryIE;
    }

    return message.AssociationSetupResponse.init(node_id.?, cause.?, recovery_time_stamp.?);
}

/// Decode Session Establishment Request message
pub fn decodeSessionEstablishmentRequest(reader: *Reader, allocator: std.mem.Allocator) MarshalError!message.SessionEstablishmentRequest {
    var node_id: ?ie.NodeId = null;
    var f_seid: ?ie.FSEID = null;

    while (reader.remaining() > 0) {
        const ie_header = try decodeIEHeader(reader);
        const ie_type: types.IEType = @enumFromInt(ie_header.ie_type);

        switch (ie_type) {
            .node_id => {
                node_id = try decodeNodeId(reader, ie_header.length, allocator);
            },
            .f_seid => {
                f_seid = try decodeFSEID(reader, ie_header.length);
            },
            else => {
                try reader.skip(ie_header.length);
            },
        }
    }

    if (node_id == null or f_seid == null) {
        return MarshalError.MissingMandatoryIE;
    }

    return message.SessionEstablishmentRequest.init(node_id.?, f_seid.?);
}

/// Decode Session Establishment Response message
pub fn decodeSessionEstablishmentResponse(reader: *Reader, allocator: std.mem.Allocator) MarshalError!message.SessionEstablishmentResponse {
    var node_id: ?ie.NodeId = null;
    var cause: ?ie.Cause = null;
    var f_seid: ?ie.FSEID = null;

    while (reader.remaining() > 0) {
        const ie_header = try decodeIEHeader(reader);
        const ie_type: types.IEType = @enumFromInt(ie_header.ie_type);

        switch (ie_type) {
            .node_id => {
                node_id = try decodeNodeId(reader, ie_header.length, allocator);
            },
            .cause => {
                cause = try decodeCause(reader, ie_header.length);
            },
            .f_seid => {
                f_seid = try decodeFSEID(reader, ie_header.length);
            },
            else => {
                try reader.skip(ie_header.length);
            },
        }
    }

    if (node_id == null or cause == null) {
        return MarshalError.MissingMandatoryIE;
    }

    var resp = message.SessionEstablishmentResponse.init(node_id.?, cause.?);
    resp.f_seid = f_seid;
    return resp;
}

test "encode and decode PFCP header without SEID" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const header = types.PfcpHeader{
        .s = false,
        .mp = false,
        .message_type = @intFromEnum(types.MessageType.heartbeat_request),
        .message_length = 8,
        .sequence_number = 12345,
    };

    try encodePfcpHeader(&writer, header);
    try std.testing.expectEqual(@as(usize, 8), writer.pos);

    var reader = Reader.init(writer.getWritten());
    const decoded = try decodePfcpHeader(&reader);

    try std.testing.expectEqual(header.s, decoded.s);
    try std.testing.expectEqual(header.message_type, decoded.message_type);
    try std.testing.expectEqual(header.message_length, decoded.message_length);
    try std.testing.expectEqual(header.sequence_number, decoded.sequence_number);
}

test "encode and decode PFCP header with SEID" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const header = types.PfcpHeader{
        .s = true,
        .mp = false,
        .message_type = @intFromEnum(types.MessageType.session_establishment_request),
        .message_length = 20,
        .seid = 0x1234567890ABCDEF,
        .sequence_number = 54321,
    };

    try encodePfcpHeader(&writer, header);
    try std.testing.expectEqual(@as(usize, 16), writer.pos);

    var reader = Reader.init(writer.getWritten());
    const decoded = try decodePfcpHeader(&reader);

    try std.testing.expectEqual(header.s, decoded.s);
    try std.testing.expectEqual(header.message_type, decoded.message_type);
    try std.testing.expectEqual(header.message_length, decoded.message_length);
    try std.testing.expectEqual(header.seid.?, decoded.seid.?);
    try std.testing.expectEqual(header.sequence_number, decoded.sequence_number);
}

test "encode and decode Recovery Time Stamp" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const rts = ie.RecoveryTimeStamp{ .timestamp = 0x12345678 };
    try encodeRecoveryTimeStamp(&writer, rts);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    try std.testing.expectEqual(@as(u16, @intFromEnum(types.IEType.recovery_time_stamp)), header.ie_type);
    try std.testing.expectEqual(@as(u16, 4), header.length);

    const decoded = try decodeRecoveryTimeStamp(&reader, header.length);
    try std.testing.expectEqual(rts.timestamp, decoded.timestamp);
}

test "encode and decode Node ID IPv4" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    try encodeNodeId(&writer, node_id);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    try std.testing.expectEqual(@as(u16, @intFromEnum(types.IEType.node_id)), header.ie_type);

    const decoded = try decodeNodeId(&reader, header.length, std.testing.allocator);
    try std.testing.expectEqual(types.NodeIdType.ipv4, decoded.node_id_type);
    try std.testing.expectEqualSlices(u8, &node_id.value.ipv4, &decoded.value.ipv4);
}

test "encode and decode F-SEID" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const fseid = ie.FSEID.initV4(0x1234567890ABCDEF, [_]u8{ 10, 0, 0, 1 });
    try encodeFSEID(&writer, fseid);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    try std.testing.expectEqual(@as(u16, @intFromEnum(types.IEType.f_seid)), header.ie_type);

    const decoded = try decodeFSEID(&reader, header.length);
    try std.testing.expectEqual(fseid.seid, decoded.seid);
    try std.testing.expect(decoded.flags.v4);
    try std.testing.expectEqualSlices(u8, &fseid.ipv4.?, &decoded.ipv4.?);
}

test "encode and decode F-TEID with CHOOSE" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const fteid = ie.FTEID.initChoose();
    try encodeFTEID(&writer, fteid);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    try std.testing.expectEqual(@as(u16, @intFromEnum(types.IEType.f_teid)), header.ie_type);

    const decoded = try decodeFTEID(&reader, header.length);
    try std.testing.expect(decoded.flags.ch);
    try std.testing.expectEqual(@as(u32, 0), decoded.teid);
}

test "encode and decode Cause" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const cause = ie.Cause.accepted();
    try encodeCause(&writer, cause);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    try std.testing.expectEqual(@as(u16, @intFromEnum(types.IEType.cause)), header.ie_type);

    const decoded = try decodeCause(&reader, header.length);
    try std.testing.expect(decoded.cause.isAccepted());
}

test "encode and decode Heartbeat Request" {
    var buffer: [1024]u8 = undefined;
    var writer = Writer.init(&buffer);

    const rts = ie.RecoveryTimeStamp{ .timestamp = 0x12345678 };
    const req = message.HeartbeatRequest.init(rts);

    try encodeHeartbeatRequest(&writer, req, 1);

    var reader = Reader.init(writer.getWritten());
    const header = try decodePfcpHeader(&reader);

    try std.testing.expectEqual(@as(u8, @intFromEnum(types.MessageType.heartbeat_request)), header.message_type);
    try std.testing.expect(!header.s);
    try std.testing.expectEqual(@as(u24, 1), header.sequence_number);
}

test "round-trip Heartbeat Request" {
    var buffer: [1024]u8 = undefined;
    var writer = Writer.init(&buffer);

    const original_rts = ie.RecoveryTimeStamp{ .timestamp = 0x12345678 };
    const original_req = message.HeartbeatRequest.init(original_rts);

    try encodeHeartbeatRequest(&writer, original_req, 42);

    var reader = Reader.init(writer.getWritten());
    const header = try decodePfcpHeader(&reader);

    try std.testing.expectEqual(@as(u24, 42), header.sequence_number);

    const decoded_req = try decodeHeartbeatRequest(&reader, std.testing.allocator);
    try std.testing.expectEqual(original_rts.timestamp, decoded_req.recovery_time_stamp.timestamp);
}

test "round-trip Association Setup Request and Response" {
    var buffer: [1024]u8 = undefined;

    // Test Request
    var writer = Writer.init(&buffer);
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const rts = ie.RecoveryTimeStamp{ .timestamp = 0x87654321 };
    const req = message.AssociationSetupRequest.init(node_id, rts);

    try encodeAssociationSetupRequest(&writer, req, 100);

    var reader = Reader.init(writer.getWritten());
    const req_header = try decodePfcpHeader(&reader);
    try std.testing.expectEqual(@as(u8, @intFromEnum(types.MessageType.association_setup_request)), req_header.message_type);
    try std.testing.expectEqual(@as(u24, 100), req_header.sequence_number);

    const decoded_req = try decodeAssociationSetupRequest(&reader, std.testing.allocator);
    try std.testing.expectEqual(types.NodeIdType.ipv4, decoded_req.node_id.node_id_type);
    try std.testing.expectEqual(rts.timestamp, decoded_req.recovery_time_stamp.timestamp);

    // Test Response
    writer = Writer.init(&buffer);
    const resp = message.AssociationSetupResponse.accepted(node_id, rts);
    try encodeAssociationSetupResponse(&writer, resp, 100);

    reader = Reader.init(writer.getWritten());
    const resp_header = try decodePfcpHeader(&reader);
    try std.testing.expectEqual(@as(u8, @intFromEnum(types.MessageType.association_setup_response)), resp_header.message_type);

    const decoded_resp = try decodeAssociationSetupResponse(&reader, std.testing.allocator);
    try std.testing.expect(decoded_resp.cause.cause.isAccepted());
}

test "round-trip Session Establishment Request and Response" {
    var buffer: [1024]u8 = undefined;

    // Test Request
    var writer = Writer.init(&buffer);
    const node_id = ie.NodeId.initIpv4([_]u8{ 10, 0, 0, 1 });
    const cp_seid: u64 = 0x1234567890ABCDEF;
    const cp_fseid = ie.FSEID.initV4(cp_seid, [_]u8{ 10, 0, 0, 1 });
    const req = message.SessionEstablishmentRequest.init(node_id, cp_fseid);

    const remote_seid: u64 = 0; // For request, remote SEID is typically 0
    try encodeSessionEstablishmentRequest(&writer, req, remote_seid, 200);

    var reader = Reader.init(writer.getWritten());
    const req_header = try decodePfcpHeader(&reader);
    try std.testing.expect(req_header.s);
    try std.testing.expectEqual(@as(u8, @intFromEnum(types.MessageType.session_establishment_request)), req_header.message_type);
    try std.testing.expectEqual(@as(u24, 200), req_header.sequence_number);

    const decoded_req = try decodeSessionEstablishmentRequest(&reader, std.testing.allocator);
    try std.testing.expectEqual(cp_seid, decoded_req.f_seid.seid);

    // Test Response
    writer = Writer.init(&buffer);
    const up_seid: u64 = 0xFEDCBA0987654321;
    const up_fseid = ie.FSEID.initV4(up_seid, [_]u8{ 10, 0, 0, 2 });
    const resp = message.SessionEstablishmentResponse.accepted(node_id, up_fseid);

    try encodeSessionEstablishmentResponse(&writer, resp, cp_seid, 200);

    reader = Reader.init(writer.getWritten());
    const resp_header = try decodePfcpHeader(&reader);
    try std.testing.expect(resp_header.s);
    try std.testing.expectEqual(cp_seid, resp_header.seid.?);

    const decoded_resp = try decodeSessionEstablishmentResponse(&reader, std.testing.allocator);
    try std.testing.expect(decoded_resp.cause.cause.isAccepted());
    try std.testing.expectEqual(up_seid, decoded_resp.f_seid.?.seid);
}

test "encode and decode UE IP Address" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const ue_ip = ie.UEIPAddress.initIpv4([_]u8{ 192, 168, 100, 1 }, true);
    try encodeUEIPAddress(&writer, ue_ip);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    try std.testing.expectEqual(@as(u16, @intFromEnum(types.IEType.ue_ip_address)), header.ie_type);

    const decoded = try decodeUEIPAddress(&reader, header.length);
    try std.testing.expect(decoded.flags.v4);
    try std.testing.expect(decoded.flags.sd);
    try std.testing.expectEqualSlices(u8, &ue_ip.ipv4.?, &decoded.ipv4.?);
}

test "encode and decode F-TEID with IPv4" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const fteid = ie.FTEID.initV4(0x12345678, [_]u8{ 192, 168, 1, 100 });
    try encodeFTEID(&writer, fteid);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    const decoded = try decodeFTEID(&reader, header.length);

    try std.testing.expectEqual(fteid.teid, decoded.teid);
    try std.testing.expect(decoded.flags.v4);
    try std.testing.expectEqualSlices(u8, &fteid.ipv4.?, &decoded.ipv4.?);
}

test "Writer and Reader basic operations" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    try writer.writeByte(0x42);
    try writer.writeU16(0x1234);
    try writer.writeU24(0xABCDEF);
    try writer.writeU32(0x12345678);
    try writer.writeU64(0x123456789ABCDEF0);

    var reader = Reader.init(writer.getWritten());
    try std.testing.expectEqual(@as(u8, 0x42), try reader.readByte());
    try std.testing.expectEqual(@as(u16, 0x1234), try reader.readU16());
    try std.testing.expectEqual(@as(u24, 0xABCDEF), try reader.readU24());
    try std.testing.expectEqual(@as(u32, 0x12345678), try reader.readU32());
    try std.testing.expectEqual(@as(u64, 0x123456789ABCDEF0), try reader.readU64());
    try std.testing.expectEqual(@as(usize, 0), reader.remaining());
}
