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

    // Encode flags (3GPP TS 29.244 Section 8.2.3)
    // Bit 0: V4, Bit 1: V6, Bit 2: CH, Bit 3: CHID (bits 4-7 spare)
    var flags: u8 = 0;
    if (fteid.flags.v4) flags |= 0x01; // V4 at bit 0
    if (fteid.flags.v6) flags |= 0x02; // V6 at bit 1
    if (fteid.flags.ch) flags |= 0x04; // CH at bit 2
    if (fteid.flags.chid) flags |= 0x08; // CHID at bit 3
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

    // Decode flags (3GPP TS 29.244 Section 8.2.3)
    // Bit 0: V4, Bit 1: V6, Bit 2: CH, Bit 3: CHID (bits 4-7 spare)
    const flags_byte = try reader.readByte();
    const v4 = (flags_byte & 0x01) != 0; // V4 at bit 0
    const v6 = (flags_byte & 0x02) != 0; // V6 at bit 1
    const ch = (flags_byte & 0x04) != 0; // CH at bit 2
    const chid = (flags_byte & 0x08) != 0; // CHID at bit 3

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

    // Encode flags (3GPP TS 29.244 Section 8.2.62)
    // Bit 0: Spare, Bit 1: V4, Bit 2: V6, Bit 3: S/D, Bit 4: IPv6D, Bit 5: CHV4, Bit 6: CHV6, Bit 7: IPV6PL
    var flags: u8 = 0;
    if (ue_ip.flags.v4) flags |= 0x02; // V4 at bit 1
    if (ue_ip.flags.v6) flags |= 0x04; // V6 at bit 2
    if (ue_ip.flags.sd) flags |= 0x08; // S/D at bit 3
    if (ue_ip.flags.ipv6d) flags |= 0x10; // IPv6D at bit 4
    if (ue_ip.flags.chv4) flags |= 0x20; // CHV4 at bit 5
    if (ue_ip.flags.chv6) flags |= 0x40; // CHV6 at bit 6
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

    // Decode flags (3GPP TS 29.244 Section 8.2.62)
    // Bit 0: Spare, Bit 1: V4, Bit 2: V6, Bit 3: S/D, Bit 4: IPv6D, Bit 5: CHV4, Bit 6: CHV6, Bit 7: IPV6PL
    const flags_byte = try reader.readByte();
    const v4 = (flags_byte & 0x02) != 0; // V4 at bit 1
    const v6 = (flags_byte & 0x04) != 0; // V6 at bit 2
    const sd = (flags_byte & 0x08) != 0; // S/D at bit 3
    const ipv6d = (flags_byte & 0x10) != 0; // IPv6D at bit 4
    const chv4 = (flags_byte & 0x20) != 0; // CHV4 at bit 5
    const chv6 = (flags_byte & 0x40) != 0; // CHV6 at bit 6

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

// ============================================================================
// Simple IE Encoding/Decoding Functions for Grouped IE Support
// ============================================================================

/// Encode Source Interface IE
pub fn encodeSourceInterface(writer: *Writer, src_iface: ie.SourceInterface) MarshalError!void {
    try encodeIEHeader(writer, .source_interface, 1);
    try writer.writeByte(@intFromEnum(src_iface.interface));
}

/// Decode Source Interface IE
pub fn decodeSourceInterface(reader: *Reader, length: u16) MarshalError!ie.SourceInterface {
    if (length < 1) return MarshalError.InvalidLength;
    const iface = try reader.readByte();
    // Skip any spare bytes
    if (length > 1) try reader.skip(length - 1);
    return ie.SourceInterface{ .interface = @enumFromInt(@as(u4, @truncate(iface))) };
}

/// Encode Destination Interface IE
pub fn encodeDestinationInterface(writer: *Writer, dst_iface: ie.DestinationInterface) MarshalError!void {
    try encodeIEHeader(writer, .destination_interface, 1);
    try writer.writeByte(@intFromEnum(dst_iface.interface));
}

/// Decode Destination Interface IE
pub fn decodeDestinationInterface(reader: *Reader, length: u16) MarshalError!ie.DestinationInterface {
    if (length < 1) return MarshalError.InvalidLength;
    const iface = try reader.readByte();
    if (length > 1) try reader.skip(length - 1);
    return ie.DestinationInterface{ .interface = @enumFromInt(@as(u4, @truncate(iface))) };
}

/// Encode Network Instance IE
pub fn encodeNetworkInstance(writer: *Writer, ni: ie.NetworkInstance) MarshalError!void {
    const len: u16 = @intCast(ni.name.len);
    try encodeIEHeader(writer, .network_instance, len);
    try writer.writeBytes(ni.name);
}

/// Decode Network Instance IE (returns slice into reader buffer)
pub fn decodeNetworkInstance(reader: *Reader, length: u16) MarshalError!ie.NetworkInstance {
    const name = try reader.readBytes(length);
    return ie.NetworkInstance{ .name = name };
}

/// Encode Apply Action IE
pub fn encodeApplyAction(writer: *Writer, action: ie.ApplyAction) MarshalError!void {
    try encodeIEHeader(writer, .apply_action, 2);
    // Encode flags - first byte
    var byte0: u8 = 0;
    if (action.actions.drop) byte0 |= 0x01;
    if (action.actions.forw) byte0 |= 0x02;
    if (action.actions.buff) byte0 |= 0x04;
    if (action.actions.nocp) byte0 |= 0x08;
    if (action.actions.dupl) byte0 |= 0x10;
    if (action.actions.ipma) byte0 |= 0x20;
    if (action.actions.ipmd) byte0 |= 0x40;
    if (action.actions.dfrt) byte0 |= 0x80;
    try writer.writeByte(byte0);
    // Second byte
    var byte1: u8 = 0;
    if (action.actions.edrt) byte1 |= 0x01;
    if (action.actions.bdpn) byte1 |= 0x02;
    if (action.actions.ddpn) byte1 |= 0x04;
    try writer.writeByte(byte1);
}

/// Decode Apply Action IE
pub fn decodeApplyAction(reader: *Reader, length: u16) MarshalError!ie.ApplyAction {
    if (length < 1) return MarshalError.InvalidLength;
    const byte0 = try reader.readByte();
    var byte1: u8 = 0;
    if (length >= 2) {
        byte1 = try reader.readByte();
    }
    if (length > 2) try reader.skip(length - 2);

    return ie.ApplyAction{
        .actions = .{
            .drop = (byte0 & 0x01) != 0,
            .forw = (byte0 & 0x02) != 0,
            .buff = (byte0 & 0x04) != 0,
            .nocp = (byte0 & 0x08) != 0,
            .dupl = (byte0 & 0x10) != 0,
            .ipma = (byte0 & 0x20) != 0,
            .ipmd = (byte0 & 0x40) != 0,
            .dfrt = (byte0 & 0x80) != 0,
            .edrt = (byte1 & 0x01) != 0,
            .bdpn = (byte1 & 0x02) != 0,
            .ddpn = (byte1 & 0x04) != 0,
        },
    };
}

/// Encode Outer Header Creation IE
pub fn encodeOuterHeaderCreation(writer: *Writer, ohc: ie.OuterHeaderCreation) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve space for header

    // Encode flags (2 bytes)
    var flags: u16 = 0;
    if (ohc.flags.gtpu_udp_ipv4) flags |= 0x0001;
    if (ohc.flags.gtpu_udp_ipv6) flags |= 0x0002;
    if (ohc.flags.udp_ipv4) flags |= 0x0004;
    if (ohc.flags.udp_ipv6) flags |= 0x0008;
    if (ohc.flags.ipv4) flags |= 0x0010;
    if (ohc.flags.ipv6) flags |= 0x0020;
    if (ohc.flags.ctag) flags |= 0x0040;
    if (ohc.flags.stag) flags |= 0x0080;
    try writer.writeU16(flags);

    // TEID if GTP-U
    if (ohc.flags.gtpu_udp_ipv4 or ohc.flags.gtpu_udp_ipv6) {
        try writer.writeU32(ohc.teid orelse 0);
    }

    // IPv4 address
    if (ohc.ipv4) |addr| {
        try writer.writeBytes(&addr);
    }

    // IPv6 address
    if (ohc.ipv6) |addr| {
        try writer.writeBytes(&addr);
    }

    // Port number
    if (ohc.port) |port| {
        try writer.writeU16(port);
    }

    // Calculate and write header
    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .outer_header_creation, ie_length);
    writer.pos = saved_pos;
}

/// Decode Outer Header Creation IE
pub fn decodeOuterHeaderCreation(reader: *Reader, length: u16) MarshalError!ie.OuterHeaderCreation {
    if (length < 2) return MarshalError.InvalidLength;

    const flags = try reader.readU16();
    var bytes_read: u16 = 2;

    const gtpu_udp_ipv4 = (flags & 0x0001) != 0;
    const gtpu_udp_ipv6 = (flags & 0x0002) != 0;
    const udp_ipv4 = (flags & 0x0004) != 0;
    const udp_ipv6 = (flags & 0x0008) != 0;
    const ipv4_flag = (flags & 0x0010) != 0;
    const ipv6_flag = (flags & 0x0020) != 0;
    const ctag_flag = (flags & 0x0040) != 0;
    const stag_flag = (flags & 0x0080) != 0;

    var teid: ?u32 = null;
    if (gtpu_udp_ipv4 or gtpu_udp_ipv6) {
        teid = try reader.readU32();
        bytes_read += 4;
    }

    var ipv4: ?[4]u8 = null;
    if (gtpu_udp_ipv4 or udp_ipv4 or ipv4_flag) {
        const addr_bytes = try reader.readBytes(4);
        var addr: [4]u8 = undefined;
        @memcpy(&addr, addr_bytes);
        ipv4 = addr;
        bytes_read += 4;
    }

    var ipv6: ?[16]u8 = null;
    if (gtpu_udp_ipv6 or udp_ipv6 or ipv6_flag) {
        const addr_bytes = try reader.readBytes(16);
        var addr: [16]u8 = undefined;
        @memcpy(&addr, addr_bytes);
        ipv6 = addr;
        bytes_read += 16;
    }

    // Skip remaining bytes (port, ctag, stag)
    if (bytes_read < length) {
        try reader.skip(length - bytes_read);
    }

    return ie.OuterHeaderCreation{
        .flags = .{
            .gtpu_udp_ipv4 = gtpu_udp_ipv4,
            .gtpu_udp_ipv6 = gtpu_udp_ipv6,
            .udp_ipv4 = udp_ipv4,
            .udp_ipv6 = udp_ipv6,
            .ipv4 = ipv4_flag,
            .ipv6 = ipv6_flag,
            .ctag = ctag_flag,
            .stag = stag_flag,
        },
        .teid = teid,
        .ipv4 = ipv4,
        .ipv6 = ipv6,
    };
}

/// Encode Outer Header Removal IE
pub fn encodeOuterHeaderRemoval(writer: *Writer, ohr: ie.OuterHeaderRemoval) MarshalError!void {
    try encodeIEHeader(writer, .outer_header_removal, 1);
    try writer.writeByte(@intFromEnum(ohr.description));
}

/// Decode Outer Header Removal IE
pub fn decodeOuterHeaderRemoval(reader: *Reader, length: u16) MarshalError!ie.OuterHeaderRemoval {
    if (length < 1) return MarshalError.InvalidLength;
    const desc = try reader.readByte();
    if (length > 1) try reader.skip(length - 1);
    return ie.OuterHeaderRemoval{ .description = @enumFromInt(desc) };
}

/// Encode SDF Filter IE
pub fn encodeSDFFilter(writer: *Writer, sdf: ie.SDFFilter) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve space for header

    // Flags (2 bytes)
    var flags: u8 = 0;
    if (sdf.flags.fd) flags |= 0x01;
    if (sdf.flags.ttc) flags |= 0x02;
    if (sdf.flags.spi) flags |= 0x04;
    if (sdf.flags.fl) flags |= 0x08;
    if (sdf.flags.bid) flags |= 0x10;
    try writer.writeByte(flags);
    try writer.writeByte(0); // Spare

    // Flow Description
    if (sdf.flow_description) |fd| {
        try writer.writeU16(@intCast(fd.len));
        try writer.writeBytes(fd);
    }

    // ToS Traffic Class
    if (sdf.tos_traffic_class) |ttc| {
        try writer.writeU16(ttc);
    }

    // Security Parameter Index
    if (sdf.security_param_index) |spi| {
        try writer.writeU32(spi);
    }

    // Flow Label
    if (sdf.flow_label) |fl| {
        try writer.writeU24(fl);
    }

    // Calculate and write header
    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .sdf_filter, ie_length);
    writer.pos = saved_pos;
}

/// Decode SDF Filter IE
pub fn decodeSDFFilter(reader: *Reader, length: u16) MarshalError!ie.SDFFilter {
    if (length < 2) return MarshalError.InvalidLength;

    const flags_byte = try reader.readByte();
    _ = try reader.readByte(); // Spare
    var bytes_read: u16 = 2;

    const fd_flag = (flags_byte & 0x01) != 0;
    const ttc_flag = (flags_byte & 0x02) != 0;
    const spi_flag = (flags_byte & 0x04) != 0;
    const fl_flag = (flags_byte & 0x08) != 0;
    const bid_flag = (flags_byte & 0x10) != 0;

    var flow_description: ?[]const u8 = null;
    if (fd_flag and bytes_read + 2 <= length) {
        const fd_len = try reader.readU16();
        bytes_read += 2;
        if (bytes_read + fd_len <= length) {
            flow_description = try reader.readBytes(fd_len);
            bytes_read += fd_len;
        }
    }

    var tos_traffic_class: ?u16 = null;
    if (ttc_flag and bytes_read + 2 <= length) {
        tos_traffic_class = try reader.readU16();
        bytes_read += 2;
    }

    var security_param_index: ?u32 = null;
    if (spi_flag and bytes_read + 4 <= length) {
        security_param_index = try reader.readU32();
        bytes_read += 4;
    }

    var flow_label: ?u24 = null;
    if (fl_flag and bytes_read + 3 <= length) {
        flow_label = try reader.readU24();
        bytes_read += 3;
    }

    if (bytes_read < length) {
        try reader.skip(length - bytes_read);
    }

    return ie.SDFFilter{
        .flags = .{
            .fd = fd_flag,
            .ttc = ttc_flag,
            .spi = spi_flag,
            .fl = fl_flag,
            .bid = bid_flag,
        },
        .flow_description = flow_description,
        .tos_traffic_class = tos_traffic_class,
        .security_param_index = security_param_index,
        .flow_label = flow_label,
    };
}

/// Encode PDR ID IE
pub fn encodePDRID(writer: *Writer, pdr_id: ie.PDRID) MarshalError!void {
    try encodeIEHeader(writer, .pdr_id, 2);
    try writer.writeU16(pdr_id.rule_id);
}

/// Decode PDR ID IE
pub fn decodePDRID(reader: *Reader, length: u16) MarshalError!ie.PDRID {
    if (length < 2) return MarshalError.InvalidLength;
    const rule_id = try reader.readU16();
    if (length > 2) try reader.skip(length - 2);
    return ie.PDRID{ .rule_id = rule_id };
}

/// Encode FAR ID IE (note: FAR ID is IE Type 88 according to spec, but we use far_id field)
pub fn encodeFARID(writer: *Writer, far_id: ie.FARID) MarshalError!void {
    // FAR ID is referenced in PDR but doesn't have its own IE type in the enum
    // It's typically encoded as part of the Create PDR or Update PDR
    // Using a custom approach: 4 bytes for the FAR ID value
    try writer.writeU16(108); // FAR ID IE type per 3GPP
    try writer.writeU16(4);
    try writer.writeU32(far_id.far_id);
}

/// Decode FAR ID IE
pub fn decodeFARID(reader: *Reader, length: u16) MarshalError!ie.FARID {
    if (length < 4) return MarshalError.InvalidLength;
    const far_id = try reader.readU32();
    if (length > 4) try reader.skip(length - 4);
    return ie.FARID{ .far_id = far_id };
}

/// Encode URR ID IE
pub fn encodeURRID(writer: *Writer, urr_id: ie.URRID) MarshalError!void {
    try encodeIEHeader(writer, .urr_id, 4);
    try writer.writeU32(urr_id.urr_id);
}

/// Decode URR ID IE
pub fn decodeURRID(reader: *Reader, length: u16) MarshalError!ie.URRID {
    if (length < 4) return MarshalError.InvalidLength;
    const urr_id = try reader.readU32();
    if (length > 4) try reader.skip(length - 4);
    return ie.URRID{ .urr_id = urr_id };
}

/// Encode QER ID IE
pub fn encodeQERID(writer: *Writer, qer_id: ie.QERID) MarshalError!void {
    // QER ID is 4 bytes per 3GPP TS 29.244
    try writer.writeU16(109); // QER ID IE type
    try writer.writeU16(4);
    try writer.writeU32(qer_id.qer_id);
}

/// Decode QER ID IE
pub fn decodeQERID(reader: *Reader, length: u16) MarshalError!ie.QERID {
    if (length < 4) return MarshalError.InvalidLength;
    const qer_id = try reader.readU32();
    if (length > 4) try reader.skip(length - 4);
    return ie.QERID{ .qer_id = qer_id };
}

/// Encode Precedence IE
pub fn encodePrecedence(writer: *Writer, precedence: ie.Precedence) MarshalError!void {
    try encodeIEHeader(writer, .precedence, 4);
    try writer.writeU32(precedence.precedence);
}

/// Decode Precedence IE
pub fn decodePrecedence(reader: *Reader, length: u16) MarshalError!ie.Precedence {
    if (length < 4) return MarshalError.InvalidLength;
    const prec = try reader.readU32();
    if (length > 4) try reader.skip(length - 4);
    return ie.Precedence{ .precedence = prec };
}

/// Encode Gate Status IE
pub fn encodeGateStatus(writer: *Writer, gate: ie.GateStatus) MarshalError!void {
    try encodeIEHeader(writer, .gate_status, 1);
    var value: u8 = 0;
    value |= (@as(u8, @intFromEnum(gate.dl_gate)) << 2);
    value |= @as(u8, @intFromEnum(gate.ul_gate));
    try writer.writeByte(value);
}

/// Decode Gate Status IE
pub fn decodeGateStatus(reader: *Reader, length: u16) MarshalError!ie.GateStatus {
    if (length < 1) return MarshalError.InvalidLength;
    const value = try reader.readByte();
    if (length > 1) try reader.skip(length - 1);
    return ie.GateStatus{
        .ul_gate = @enumFromInt(@as(u2, @truncate(value))),
        .dl_gate = @enumFromInt(@as(u2, @truncate(value >> 2))),
    };
}

/// Encode MBR IE
pub fn encodeMBR(writer: *Writer, mbr: ie.MBR) MarshalError!void {
    try encodeIEHeader(writer, .mbr, 10);
    // UL MBR (5 bytes, first byte is length=5)
    try writer.writeU32(@truncate(mbr.ul_mbr >> 8));
    try writer.writeByte(@truncate(mbr.ul_mbr));
    // DL MBR (5 bytes)
    try writer.writeU32(@truncate(mbr.dl_mbr >> 8));
    try writer.writeByte(@truncate(mbr.dl_mbr));
}

/// Decode MBR IE
pub fn decodeMBR(reader: *Reader, length: u16) MarshalError!ie.MBR {
    if (length < 10) return MarshalError.InvalidLength;
    // Read UL MBR (5 bytes)
    const ul_hi = try reader.readU32();
    const ul_lo = try reader.readByte();
    const ul_mbr: u64 = (@as(u64, ul_hi) << 8) | @as(u64, ul_lo);
    // Read DL MBR (5 bytes)
    const dl_hi = try reader.readU32();
    const dl_lo = try reader.readByte();
    const dl_mbr: u64 = (@as(u64, dl_hi) << 8) | @as(u64, dl_lo);
    if (length > 10) try reader.skip(length - 10);
    return ie.MBR{ .ul_mbr = ul_mbr, .dl_mbr = dl_mbr };
}

/// Encode GBR IE
pub fn encodeGBR(writer: *Writer, gbr: ie.GBR) MarshalError!void {
    try encodeIEHeader(writer, .gbr, 10);
    // UL GBR (5 bytes)
    try writer.writeU32(@truncate(gbr.ul_gbr >> 8));
    try writer.writeByte(@truncate(gbr.ul_gbr));
    // DL GBR (5 bytes)
    try writer.writeU32(@truncate(gbr.dl_gbr >> 8));
    try writer.writeByte(@truncate(gbr.dl_gbr));
}

/// Decode GBR IE
pub fn decodeGBR(reader: *Reader, length: u16) MarshalError!ie.GBR {
    if (length < 10) return MarshalError.InvalidLength;
    const ul_hi = try reader.readU32();
    const ul_lo = try reader.readByte();
    const ul_gbr: u64 = (@as(u64, ul_hi) << 8) | @as(u64, ul_lo);
    const dl_hi = try reader.readU32();
    const dl_lo = try reader.readByte();
    const dl_gbr: u64 = (@as(u64, dl_hi) << 8) | @as(u64, dl_lo);
    if (length > 10) try reader.skip(length - 10);
    return ie.GBR{ .ul_gbr = ul_gbr, .dl_gbr = dl_gbr };
}

/// Encode QER Correlation ID IE
pub fn encodeQERCorrelationID(writer: *Writer, corr_id: u32) MarshalError!void {
    try encodeIEHeader(writer, .qer_correlation_id, 4);
    try writer.writeU32(corr_id);
}

/// Decode QER Correlation ID IE
pub fn decodeQERCorrelationID(reader: *Reader, length: u16) MarshalError!u32 {
    if (length < 4) return MarshalError.InvalidLength;
    const corr_id = try reader.readU32();
    if (length > 4) try reader.skip(length - 4);
    return corr_id;
}

/// Encode Measurement Method IE
pub fn encodeMeasurementMethod(writer: *Writer, mm: ie.MeasurementMethod) MarshalError!void {
    try encodeIEHeader(writer, .measurement_method, 1);
    var value: u8 = 0;
    if (mm.flags.durat) value |= 0x01;
    if (mm.flags.volum) value |= 0x02;
    if (mm.flags.event) value |= 0x04;
    try writer.writeByte(value);
}

/// Decode Measurement Method IE
pub fn decodeMeasurementMethod(reader: *Reader, length: u16) MarshalError!ie.MeasurementMethod {
    if (length < 1) return MarshalError.InvalidLength;
    const value = try reader.readByte();
    if (length > 1) try reader.skip(length - 1);
    return ie.MeasurementMethod{
        .flags = .{
            .durat = (value & 0x01) != 0,
            .volum = (value & 0x02) != 0,
            .event = (value & 0x04) != 0,
        },
    };
}

/// Encode Reporting Triggers IE
pub fn encodeReportingTriggers(writer: *Writer, rt: ie.ReportingTriggers) MarshalError!void {
    try encodeIEHeader(writer, .reporting_triggers, 2);
    var byte0: u8 = 0;
    if (rt.flags.perio) byte0 |= 0x01;
    if (rt.flags.volth) byte0 |= 0x02;
    if (rt.flags.timth) byte0 |= 0x04;
    if (rt.flags.quhti) byte0 |= 0x08;
    if (rt.flags.start) byte0 |= 0x10;
    if (rt.flags.stopt) byte0 |= 0x20;
    if (rt.flags.droth) byte0 |= 0x40;
    if (rt.flags.liusa) byte0 |= 0x80;
    try writer.writeByte(byte0);
    var byte1: u8 = 0;
    if (rt.flags.volqu) byte1 |= 0x01;
    if (rt.flags.timqu) byte1 |= 0x02;
    if (rt.flags.envcl) byte1 |= 0x04;
    if (rt.flags.monit) byte1 |= 0x08;
    if (rt.flags.termr) byte1 |= 0x10;
    try writer.writeByte(byte1);
}

/// Decode Reporting Triggers IE
pub fn decodeReportingTriggers(reader: *Reader, length: u16) MarshalError!ie.ReportingTriggers {
    if (length < 2) return MarshalError.InvalidLength;
    const byte0 = try reader.readByte();
    const byte1 = try reader.readByte();
    if (length > 2) try reader.skip(length - 2);
    return ie.ReportingTriggers{
        .flags = .{
            .perio = (byte0 & 0x01) != 0,
            .volth = (byte0 & 0x02) != 0,
            .timth = (byte0 & 0x04) != 0,
            .quhti = (byte0 & 0x08) != 0,
            .start = (byte0 & 0x10) != 0,
            .stopt = (byte0 & 0x20) != 0,
            .droth = (byte0 & 0x40) != 0,
            .liusa = (byte0 & 0x80) != 0,
            .volqu = (byte1 & 0x01) != 0,
            .timqu = (byte1 & 0x02) != 0,
            .envcl = (byte1 & 0x04) != 0,
            .monit = (byte1 & 0x08) != 0,
            .termr = (byte1 & 0x10) != 0,
        },
    };
}

/// Encode Volume Threshold IE
pub fn encodeVolumeThreshold(writer: *Writer, vt: ie.VolumeThreshold) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve header

    var flags: u8 = 0;
    if (vt.flags.tovol) flags |= 0x01;
    if (vt.flags.ulvol) flags |= 0x02;
    if (vt.flags.dlvol) flags |= 0x04;
    try writer.writeByte(flags);

    if (vt.total_volume) |v| try writer.writeU64(v);
    if (vt.uplink_volume) |v| try writer.writeU64(v);
    if (vt.downlink_volume) |v| try writer.writeU64(v);

    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .volume_threshold, ie_length);
    writer.pos = saved_pos;
}

/// Decode Volume Threshold IE
pub fn decodeVolumeThreshold(reader: *Reader, length: u16) MarshalError!ie.VolumeThreshold {
    if (length < 1) return MarshalError.InvalidLength;
    const flags = try reader.readByte();
    var bytes_read: u16 = 1;

    const tovol = (flags & 0x01) != 0;
    const ulvol = (flags & 0x02) != 0;
    const dlvol = (flags & 0x04) != 0;

    var total_volume: ?u64 = null;
    var uplink_volume: ?u64 = null;
    var downlink_volume: ?u64 = null;

    if (tovol) {
        total_volume = try reader.readU64();
        bytes_read += 8;
    }
    if (ulvol) {
        uplink_volume = try reader.readU64();
        bytes_read += 8;
    }
    if (dlvol) {
        downlink_volume = try reader.readU64();
        bytes_read += 8;
    }

    if (bytes_read < length) try reader.skip(length - bytes_read);

    return ie.VolumeThreshold{
        .flags = .{ .tovol = tovol, .ulvol = ulvol, .dlvol = dlvol },
        .total_volume = total_volume,
        .uplink_volume = uplink_volume,
        .downlink_volume = downlink_volume,
    };
}

/// Encode Time Threshold IE
pub fn encodeTimeThreshold(writer: *Writer, tt: ie.TimeThreshold) MarshalError!void {
    try encodeIEHeader(writer, .time_threshold, 4);
    try writer.writeU32(tt.threshold);
}

/// Decode Time Threshold IE
pub fn decodeTimeThreshold(reader: *Reader, length: u16) MarshalError!ie.TimeThreshold {
    if (length < 4) return MarshalError.InvalidLength;
    const threshold = try reader.readU32();
    if (length > 4) try reader.skip(length - 4);
    return ie.TimeThreshold{ .threshold = threshold };
}

/// Encode Measurement Period IE
pub fn encodeMeasurementPeriod(writer: *Writer, period: u32) MarshalError!void {
    try encodeIEHeader(writer, .measurement_period, 4);
    try writer.writeU32(period);
}

/// Decode Measurement Period IE
pub fn decodeMeasurementPeriod(reader: *Reader, length: u16) MarshalError!u32 {
    if (length < 4) return MarshalError.InvalidLength;
    const period = try reader.readU32();
    if (length > 4) try reader.skip(length - 4);
    return period;
}

// ============================================================================
// Grouped IE Encoding/Decoding Functions
// ============================================================================

/// Encode PDI (Packet Detection Information) Grouped IE
pub fn encodePDI(writer: *Writer, pdi: ie.PDI) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve header

    // Source Interface (mandatory)
    try encodeSourceInterface(writer, pdi.source_interface);

    // F-TEID (optional)
    if (pdi.f_teid) |fteid| {
        try encodeFTEID(writer, fteid);
    }

    // Network Instance (optional)
    if (pdi.network_instance) |ni| {
        try encodeNetworkInstance(writer, ni);
    }

    // UE IP Address (optional)
    if (pdi.ue_ip_address) |ue_ip| {
        try encodeUEIPAddress(writer, ue_ip);
    }

    // SDF Filter (optional)
    if (pdi.sdf_filter) |sdf| {
        try encodeSDFFilter(writer, sdf);
    }

    // Application ID (optional)
    if (pdi.application_id) |app_id| {
        try encodeIEHeader(writer, .application_id, @intCast(app_id.len));
        try writer.writeBytes(app_id);
    }

    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .pdi, ie_length);
    writer.pos = saved_pos;
}

/// Decode PDI Grouped IE
pub fn decodePDI(reader: *Reader, length: u16, allocator: std.mem.Allocator) MarshalError!ie.PDI {
    _ = allocator;
    const end_pos = reader.pos + length;

    var source_interface: ?ie.SourceInterface = null;
    var f_teid: ?ie.FTEID = null;
    var network_instance: ?ie.NetworkInstance = null;
    var ue_ip_address: ?ie.UEIPAddress = null;
    var sdf_filter: ?ie.SDFFilter = null;
    var application_id: ?[]const u8 = null;

    while (reader.pos < end_pos) {
        const ie_header = try decodeIEHeader(reader);
        const ie_type: types.IEType = @enumFromInt(ie_header.ie_type);

        switch (ie_type) {
            .source_interface => source_interface = try decodeSourceInterface(reader, ie_header.length),
            .f_teid => f_teid = try decodeFTEID(reader, ie_header.length),
            .network_instance => network_instance = try decodeNetworkInstance(reader, ie_header.length),
            .ue_ip_address => ue_ip_address = try decodeUEIPAddress(reader, ie_header.length),
            .sdf_filter => sdf_filter = try decodeSDFFilter(reader, ie_header.length),
            .application_id => application_id = try reader.readBytes(ie_header.length),
            else => try reader.skip(ie_header.length),
        }
    }

    if (source_interface == null) return MarshalError.MissingMandatoryIE;

    return ie.PDI{
        .source_interface = source_interface.?,
        .f_teid = f_teid,
        .network_instance = network_instance,
        .ue_ip_address = ue_ip_address,
        .sdf_filter = sdf_filter,
        .application_id = application_id,
    };
}

/// Encode Forwarding Parameters Grouped IE
pub fn encodeForwardingParameters(writer: *Writer, fp: ie.ForwardingParameters) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve header

    // Destination Interface (mandatory)
    try encodeDestinationInterface(writer, fp.destination_interface);

    // Network Instance (optional)
    if (fp.network_instance) |ni| {
        try encodeNetworkInstance(writer, ni);
    }

    // Outer Header Creation (optional)
    if (fp.outer_header_creation) |ohc| {
        try encodeOuterHeaderCreation(writer, ohc);
    }

    // Forwarding Policy (optional)
    if (fp.forwarding_policy) |policy| {
        try encodeIEHeader(writer, .forwarding_policy, @intCast(policy.len));
        try writer.writeBytes(policy);
    }

    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .forwarding_parameters, ie_length);
    writer.pos = saved_pos;
}

/// Decode Forwarding Parameters Grouped IE
pub fn decodeForwardingParameters(reader: *Reader, length: u16, allocator: std.mem.Allocator) MarshalError!ie.ForwardingParameters {
    _ = allocator;
    const end_pos = reader.pos + length;

    var destination_interface: ?ie.DestinationInterface = null;
    var network_instance: ?ie.NetworkInstance = null;
    var outer_header_creation: ?ie.OuterHeaderCreation = null;
    var forwarding_policy: ?[]const u8 = null;

    while (reader.pos < end_pos) {
        const ie_header = try decodeIEHeader(reader);
        const ie_type: types.IEType = @enumFromInt(ie_header.ie_type);

        switch (ie_type) {
            .destination_interface => destination_interface = try decodeDestinationInterface(reader, ie_header.length),
            .network_instance => network_instance = try decodeNetworkInstance(reader, ie_header.length),
            .outer_header_creation => outer_header_creation = try decodeOuterHeaderCreation(reader, ie_header.length),
            .forwarding_policy => forwarding_policy = try reader.readBytes(ie_header.length),
            else => try reader.skip(ie_header.length),
        }
    }

    if (destination_interface == null) return MarshalError.MissingMandatoryIE;

    return ie.ForwardingParameters{
        .destination_interface = destination_interface.?,
        .network_instance = network_instance,
        .outer_header_creation = outer_header_creation,
        .forwarding_policy = forwarding_policy,
    };
}

/// Encode Create PDR Grouped IE
pub fn encodeCreatePDR(writer: *Writer, pdr: ie.CreatePDR) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve header

    // PDR ID (mandatory)
    try encodePDRID(writer, pdr.pdr_id);

    // Precedence (mandatory)
    try encodePrecedence(writer, pdr.precedence);

    // PDI (mandatory)
    try encodePDI(writer, pdr.pdi);

    // FAR ID (optional)
    if (pdr.far_id) |far_id| {
        try encodeFARID(writer, far_id);
    }

    // URR IDs (optional)
    if (pdr.urr_ids) |urr_ids| {
        for (urr_ids) |urr_id| {
            try encodeURRID(writer, urr_id);
        }
    }

    // QER IDs (optional)
    if (pdr.qer_ids) |qer_ids| {
        for (qer_ids) |qer_id| {
            try encodeQERID(writer, qer_id);
        }
    }

    // Outer Header Removal (optional)
    if (pdr.outer_header_removal) |ohr| {
        try encodeOuterHeaderRemoval(writer, ohr);
    }

    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .create_pdr, ie_length);
    writer.pos = saved_pos;
}

/// Decode Create PDR Grouped IE
pub fn decodeCreatePDR(reader: *Reader, length: u16, allocator: std.mem.Allocator) MarshalError!ie.CreatePDR {
    const end_pos = reader.pos + length;

    var pdr_id: ?ie.PDRID = null;
    var precedence: ?ie.Precedence = null;
    var pdi: ?ie.PDI = null;
    var far_id: ?ie.FARID = null;
    var outer_header_removal: ?ie.OuterHeaderRemoval = null;

    // For arrays, we'll count first then allocate
    var urr_count: usize = 0;
    var qer_count: usize = 0;

    // First pass: count URR and QER IDs
    const first_pass_start = reader.pos;
    while (reader.pos < end_pos) {
        const ie_header = try decodeIEHeader(reader);
        if (ie_header.ie_type == @intFromEnum(types.IEType.urr_id)) {
            urr_count += 1;
        } else if (ie_header.ie_type == 109) { // QER ID
            qer_count += 1;
        }
        try reader.skip(ie_header.length);
    }

    // Reset reader position
    reader.pos = first_pass_start;

    // Allocate arrays if needed
    var urr_ids: ?[]ie.URRID = null;
    var qer_ids: ?[]ie.QERID = null;
    var urr_idx: usize = 0;
    var qer_idx: usize = 0;

    if (urr_count > 0) {
        urr_ids = try allocator.alloc(ie.URRID, urr_count);
    }
    if (qer_count > 0) {
        qer_ids = try allocator.alloc(ie.QERID, qer_count);
    }

    // Second pass: decode IEs
    while (reader.pos < end_pos) {
        const ie_header = try decodeIEHeader(reader);
        const ie_type: types.IEType = @enumFromInt(ie_header.ie_type);

        switch (ie_type) {
            .pdr_id => pdr_id = try decodePDRID(reader, ie_header.length),
            .precedence => precedence = try decodePrecedence(reader, ie_header.length),
            .pdi => pdi = try decodePDI(reader, ie_header.length, allocator),
            .urr_id => {
                if (urr_ids) |ids| {
                    ids[urr_idx] = try decodeURRID(reader, ie_header.length);
                    urr_idx += 1;
                }
            },
            .outer_header_removal => outer_header_removal = try decodeOuterHeaderRemoval(reader, ie_header.length),
            else => {
                // Handle FAR ID (type 108) and QER ID (type 109)
                if (ie_header.ie_type == 108) {
                    far_id = try decodeFARID(reader, ie_header.length);
                } else if (ie_header.ie_type == 109) {
                    if (qer_ids) |ids| {
                        ids[qer_idx] = try decodeQERID(reader, ie_header.length);
                        qer_idx += 1;
                    }
                } else {
                    try reader.skip(ie_header.length);
                }
            },
        }
    }

    if (pdr_id == null or precedence == null or pdi == null) {
        return MarshalError.MissingMandatoryIE;
    }

    return ie.CreatePDR{
        .pdr_id = pdr_id.?,
        .precedence = precedence.?,
        .pdi = pdi.?,
        .far_id = far_id,
        .urr_ids = urr_ids,
        .qer_ids = qer_ids,
        .outer_header_removal = outer_header_removal,
    };
}

/// Encode Create FAR Grouped IE
pub fn encodeCreateFAR(writer: *Writer, far: ie.CreateFAR) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve header

    // FAR ID (mandatory)
    try encodeFARID(writer, far.far_id);

    // Apply Action (mandatory)
    try encodeApplyAction(writer, far.apply_action);

    // Forwarding Parameters (optional)
    if (far.forwarding_parameters) |fp| {
        try encodeForwardingParameters(writer, fp);
    }

    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .create_far, ie_length);
    writer.pos = saved_pos;
}

/// Decode Create FAR Grouped IE
pub fn decodeCreateFAR(reader: *Reader, length: u16, allocator: std.mem.Allocator) MarshalError!ie.CreateFAR {
    const end_pos = reader.pos + length;

    var far_id: ?ie.FARID = null;
    var apply_action: ?ie.ApplyAction = null;
    var forwarding_parameters: ?ie.ForwardingParameters = null;

    while (reader.pos < end_pos) {
        const ie_header = try decodeIEHeader(reader);
        const ie_type: types.IEType = @enumFromInt(ie_header.ie_type);

        switch (ie_type) {
            .apply_action => apply_action = try decodeApplyAction(reader, ie_header.length),
            .forwarding_parameters => forwarding_parameters = try decodeForwardingParameters(reader, ie_header.length, allocator),
            else => {
                // FAR ID is type 108
                if (ie_header.ie_type == 108) {
                    far_id = try decodeFARID(reader, ie_header.length);
                } else {
                    try reader.skip(ie_header.length);
                }
            },
        }
    }

    if (far_id == null or apply_action == null) {
        return MarshalError.MissingMandatoryIE;
    }

    return ie.CreateFAR{
        .far_id = far_id.?,
        .apply_action = apply_action.?,
        .forwarding_parameters = forwarding_parameters,
    };
}

/// Encode Create QER Grouped IE
pub fn encodeCreateQER(writer: *Writer, qer: ie.CreateQER) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve header

    // QER ID (mandatory)
    try encodeQERID(writer, qer.qer_id);

    // Gate Status (optional)
    if (qer.gate_status) |gs| {
        try encodeGateStatus(writer, gs);
    }

    // MBR (optional)
    if (qer.mbr) |mbr| {
        try encodeMBR(writer, mbr);
    }

    // GBR (optional)
    if (qer.gbr) |gbr| {
        try encodeGBR(writer, gbr);
    }

    // QER Correlation ID (optional)
    if (qer.qer_correlation_id) |corr_id| {
        try encodeQERCorrelationID(writer, corr_id);
    }

    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .create_qer, ie_length);
    writer.pos = saved_pos;
}

/// Decode Create QER Grouped IE
pub fn decodeCreateQER(reader: *Reader, length: u16, allocator: std.mem.Allocator) MarshalError!ie.CreateQER {
    _ = allocator;
    const end_pos = reader.pos + length;

    var qer_id: ?ie.QERID = null;
    var gate_status: ?ie.GateStatus = null;
    var mbr: ?ie.MBR = null;
    var gbr: ?ie.GBR = null;
    var qer_correlation_id: ?u32 = null;

    while (reader.pos < end_pos) {
        const ie_header = try decodeIEHeader(reader);
        const ie_type: types.IEType = @enumFromInt(ie_header.ie_type);

        switch (ie_type) {
            .gate_status => gate_status = try decodeGateStatus(reader, ie_header.length),
            .mbr => mbr = try decodeMBR(reader, ie_header.length),
            .gbr => gbr = try decodeGBR(reader, ie_header.length),
            .qer_correlation_id => qer_correlation_id = try decodeQERCorrelationID(reader, ie_header.length),
            else => {
                // QER ID is type 109
                if (ie_header.ie_type == 109) {
                    qer_id = try decodeQERID(reader, ie_header.length);
                } else {
                    try reader.skip(ie_header.length);
                }
            },
        }
    }

    if (qer_id == null) {
        return MarshalError.MissingMandatoryIE;
    }

    return ie.CreateQER{
        .qer_id = qer_id.?,
        .gate_status = gate_status,
        .mbr = mbr,
        .gbr = gbr,
        .qer_correlation_id = qer_correlation_id,
    };
}

/// Encode Create URR Grouped IE
pub fn encodeCreateURR(writer: *Writer, urr: ie.CreateURR) MarshalError!void {
    const start_pos = writer.pos;
    try writer.skip(4); // Reserve header

    // URR ID (mandatory)
    try encodeURRID(writer, urr.urr_id);

    // Measurement Method (mandatory)
    try encodeMeasurementMethod(writer, urr.measurement_method);

    // Reporting Triggers (optional)
    if (urr.reporting_triggers) |rt| {
        try encodeReportingTriggers(writer, rt);
    }

    // Volume Threshold (optional)
    if (urr.volume_threshold) |vt| {
        try encodeVolumeThreshold(writer, vt);
    }

    // Time Threshold (optional)
    if (urr.time_threshold) |tt| {
        try encodeTimeThreshold(writer, tt);
    }

    // Measurement Period (optional)
    if (urr.measurement_period) |mp| {
        try encodeMeasurementPeriod(writer, mp);
    }

    const ie_length: u16 = @intCast(writer.pos - start_pos - 4);
    const saved_pos = writer.pos;
    writer.pos = start_pos;
    try encodeIEHeader(writer, .create_urr, ie_length);
    writer.pos = saved_pos;
}

/// Decode Create URR Grouped IE
pub fn decodeCreateURR(reader: *Reader, length: u16, allocator: std.mem.Allocator) MarshalError!ie.CreateURR {
    _ = allocator;
    const end_pos = reader.pos + length;

    var urr_id: ?ie.URRID = null;
    var measurement_method: ?ie.MeasurementMethod = null;
    var reporting_triggers: ?ie.ReportingTriggers = null;
    var volume_threshold: ?ie.VolumeThreshold = null;
    var time_threshold: ?ie.TimeThreshold = null;
    var measurement_period: ?u32 = null;

    while (reader.pos < end_pos) {
        const ie_header = try decodeIEHeader(reader);
        const ie_type: types.IEType = @enumFromInt(ie_header.ie_type);

        switch (ie_type) {
            .urr_id => urr_id = try decodeURRID(reader, ie_header.length),
            .measurement_method => measurement_method = try decodeMeasurementMethod(reader, ie_header.length),
            .reporting_triggers => reporting_triggers = try decodeReportingTriggers(reader, ie_header.length),
            .volume_threshold => volume_threshold = try decodeVolumeThreshold(reader, ie_header.length),
            .time_threshold => time_threshold = try decodeTimeThreshold(reader, ie_header.length),
            .measurement_period => measurement_period = try decodeMeasurementPeriod(reader, ie_header.length),
            else => try reader.skip(ie_header.length),
        }
    }

    if (urr_id == null or measurement_method == null) {
        return MarshalError.MissingMandatoryIE;
    }

    return ie.CreateURR{
        .urr_id = urr_id.?,
        .measurement_method = measurement_method.?,
        .reporting_triggers = reporting_triggers,
        .volume_threshold = volume_threshold,
        .time_threshold = time_threshold,
        .measurement_period = measurement_period,
    };
}

// ============================================================================
// Tests
// ============================================================================

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

// ============================================================================
// Grouped IE Tests
// ============================================================================

test "encode and decode Source Interface" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const src_iface = ie.SourceInterface.init(.access);
    try encodeSourceInterface(&writer, src_iface);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    try std.testing.expectEqual(@as(u16, @intFromEnum(types.IEType.source_interface)), header.ie_type);

    const decoded = try decodeSourceInterface(&reader, header.length);
    try std.testing.expectEqual(types.SourceInterface.access, decoded.interface);
}

test "encode and decode Apply Action" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const action = ie.ApplyAction.forward();
    try encodeApplyAction(&writer, action);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    const decoded = try decodeApplyAction(&reader, header.length);

    try std.testing.expect(decoded.actions.forw);
    try std.testing.expect(!decoded.actions.drop);
}

test "encode and decode Outer Header Creation IPv4" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const ohc = ie.OuterHeaderCreation.initGtpuV4(0x12345678, [_]u8{ 10, 0, 0, 1 });
    try encodeOuterHeaderCreation(&writer, ohc);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    const decoded = try decodeOuterHeaderCreation(&reader, header.length);

    try std.testing.expect(decoded.flags.gtpu_udp_ipv4);
    try std.testing.expectEqual(@as(u32, 0x12345678), decoded.teid.?);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 10, 0, 0, 1 }, &decoded.ipv4.?);
}

test "encode and decode Precedence" {
    var buffer: [100]u8 = undefined;
    var writer = Writer.init(&buffer);

    const prec = ie.Precedence.init(100);
    try encodePrecedence(&writer, prec);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    const decoded = try decodePrecedence(&reader, header.length);

    try std.testing.expectEqual(@as(u32, 100), decoded.precedence);
}

test "encode and decode PDI" {
    var buffer: [512]u8 = undefined;
    var writer = Writer.init(&buffer);

    const src_iface = ie.SourceInterface.init(.access);
    const f_teid = ie.FTEID.initV4(0xAABBCCDD, [_]u8{ 192, 168, 1, 100 });
    const pdi = ie.PDI.init(src_iface).withFTeid(f_teid);

    try encodePDI(&writer, pdi);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    try std.testing.expectEqual(@as(u16, @intFromEnum(types.IEType.pdi)), header.ie_type);

    const decoded = try decodePDI(&reader, header.length, std.testing.allocator);
    try std.testing.expectEqual(types.SourceInterface.access, decoded.source_interface.interface);
    try std.testing.expect(decoded.f_teid != null);
    try std.testing.expectEqual(@as(u32, 0xAABBCCDD), decoded.f_teid.?.teid);
}

test "encode and decode Create PDR" {
    var buffer: [1024]u8 = undefined;
    var writer = Writer.init(&buffer);

    const pdr_id = ie.PDRID.init(1);
    const precedence = ie.Precedence.init(100);
    const src_iface = ie.SourceInterface.init(.access);
    const pdi = ie.PDI.init(src_iface);
    const far_id = ie.FARID.init(1);

    const pdr = ie.CreatePDR.init(pdr_id, precedence, pdi).withFarId(far_id);

    try encodeCreatePDR(&writer, pdr);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    try std.testing.expectEqual(@as(u16, @intFromEnum(types.IEType.create_pdr)), header.ie_type);

    const decoded = try decodeCreatePDR(&reader, header.length, std.testing.allocator);
    try std.testing.expectEqual(@as(u16, 1), decoded.pdr_id.rule_id);
    try std.testing.expectEqual(@as(u32, 100), decoded.precedence.precedence);
    try std.testing.expectEqual(types.SourceInterface.access, decoded.pdi.source_interface.interface);
    try std.testing.expect(decoded.far_id != null);
    try std.testing.expectEqual(@as(u32, 1), decoded.far_id.?.far_id);
}

test "encode and decode Create FAR with forwarding" {
    var buffer: [1024]u8 = undefined;
    var writer = Writer.init(&buffer);

    const far_id = ie.FARID.init(1);
    const dest_iface = ie.DestinationInterface.init(.core);
    const ohc = ie.OuterHeaderCreation.initGtpuV4(0x12345678, [_]u8{ 10, 0, 0, 1 });
    const fp = ie.ForwardingParameters.init(dest_iface).withOuterHeaderCreation(ohc);
    const far = ie.CreateFAR.init(far_id, ie.ApplyAction.forward()).withForwardingParameters(fp);

    try encodeCreateFAR(&writer, far);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    try std.testing.expectEqual(@as(u16, @intFromEnum(types.IEType.create_far)), header.ie_type);

    const decoded = try decodeCreateFAR(&reader, header.length, std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 1), decoded.far_id.far_id);
    try std.testing.expect(decoded.apply_action.actions.forw);
    try std.testing.expect(decoded.forwarding_parameters != null);
    try std.testing.expect(decoded.forwarding_parameters.?.outer_header_creation != null);
    try std.testing.expectEqual(@as(u32, 0x12345678), decoded.forwarding_parameters.?.outer_header_creation.?.teid.?);
}

test "encode and decode Create FAR drop" {
    var buffer: [256]u8 = undefined;
    var writer = Writer.init(&buffer);

    const far = ie.CreateFAR.drop(ie.FARID.init(2));

    try encodeCreateFAR(&writer, far);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    const decoded = try decodeCreateFAR(&reader, header.length, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 2), decoded.far_id.far_id);
    try std.testing.expect(decoded.apply_action.actions.drop);
    try std.testing.expect(decoded.forwarding_parameters == null);
}

test "encode and decode Create QER with rate limits" {
    var buffer: [256]u8 = undefined;
    var writer = Writer.init(&buffer);

    const qer_id = ie.QERID.init(1);
    const ul_mbr: u64 = 100_000_000; // 100 Mbps
    const dl_mbr: u64 = 200_000_000; // 200 Mbps
    const ul_gbr: u64 = 50_000_000; // 50 Mbps
    const dl_gbr: u64 = 100_000_000; // 100 Mbps

    const qer = ie.CreateQER.withRates(qer_id, ul_mbr, dl_mbr, ul_gbr, dl_gbr);

    try encodeCreateQER(&writer, qer);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    try std.testing.expectEqual(@as(u16, @intFromEnum(types.IEType.create_qer)), header.ie_type);

    const decoded = try decodeCreateQER(&reader, header.length, std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 1), decoded.qer_id.qer_id);
    try std.testing.expect(decoded.gate_status != null);
    try std.testing.expectEqual(ie.GateStatus.GateValue.open, decoded.gate_status.?.ul_gate);
    try std.testing.expect(decoded.mbr != null);
    try std.testing.expect(decoded.gbr != null);
}

test "encode and decode Create URR with volume threshold" {
    var buffer: [256]u8 = undefined;
    var writer = Writer.init(&buffer);

    const urr_id = ie.URRID.init(1);
    const mm = ie.MeasurementMethod.volume();
    const vt = ie.VolumeThreshold.initTotal(1_000_000_000);

    const urr = ie.CreateURR.init(urr_id, mm).withVolumeThreshold(vt);

    try encodeCreateURR(&writer, urr);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    try std.testing.expectEqual(@as(u16, @intFromEnum(types.IEType.create_urr)), header.ie_type);

    const decoded = try decodeCreateURR(&reader, header.length, std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 1), decoded.urr_id.urr_id);
    try std.testing.expect(decoded.measurement_method.flags.volum);
    try std.testing.expect(decoded.volume_threshold != null);
    try std.testing.expectEqual(@as(u64, 1_000_000_000), decoded.volume_threshold.?.total_volume.?);
    try std.testing.expect(decoded.reporting_triggers != null);
    try std.testing.expect(decoded.reporting_triggers.?.flags.volth);
}

test "encode and decode Create URR periodic" {
    var buffer: [256]u8 = undefined;
    var writer = Writer.init(&buffer);

    const urr = ie.CreateURR.withPeriodic(ie.URRID.init(2), 60);

    try encodeCreateURR(&writer, urr);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    const decoded = try decodeCreateURR(&reader, header.length, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 2), decoded.urr_id.urr_id);
    try std.testing.expect(decoded.measurement_method.flags.volum);
    try std.testing.expectEqual(@as(u32, 60), decoded.measurement_period.?);
    try std.testing.expect(decoded.reporting_triggers != null);
    try std.testing.expect(decoded.reporting_triggers.?.flags.perio);
}

test "encode and decode complete PDR with all components" {
    var buffer: [2048]u8 = undefined;
    var writer = Writer.init(&buffer);

    // Create a complete PDR
    const pdr_id = ie.PDRID.init(1);
    const precedence = ie.Precedence.init(100);
    const src_iface = ie.SourceInterface.init(.access);
    const f_teid = ie.FTEID.initV4(0xAABBCCDD, [_]u8{ 192, 168, 1, 100 });
    const ue_ip = ie.UEIPAddress.initIpv4([_]u8{ 10, 0, 0, 1 }, false);

    const pdi = ie.PDI.init(src_iface)
        .withFTeid(f_teid)
        .withUeIp(ue_ip);

    const far_id = ie.FARID.init(1);
    const ohr = ie.OuterHeaderRemoval.gtpuUdpIpv4();

    const pdr = ie.CreatePDR.init(pdr_id, precedence, pdi)
        .withFarId(far_id)
        .withOuterHeaderRemoval(ohr);

    try encodeCreatePDR(&writer, pdr);

    var reader = Reader.init(writer.getWritten());
    const header = try decodeIEHeader(&reader);
    const decoded = try decodeCreatePDR(&reader, header.length, std.testing.allocator);

    try std.testing.expectEqual(@as(u16, 1), decoded.pdr_id.rule_id);
    try std.testing.expectEqual(@as(u32, 100), decoded.precedence.precedence);
    try std.testing.expect(decoded.pdi.f_teid != null);
    try std.testing.expect(decoded.pdi.ue_ip_address != null);
    try std.testing.expect(decoded.far_id != null);
    try std.testing.expect(decoded.outer_header_removal != null);
}
