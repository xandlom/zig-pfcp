// PFCP Network Layer module
// Handles UDP socket communication, sequence numbers, and retransmission
// 3GPP TS 29.244

const std = @import("std");
const types = @import("types.zig");
const marshal = @import("marshal.zig");
const net = std.net;
const Allocator = std.mem.Allocator;

/// Network layer errors
pub const NetError = error{
    SocketCreationFailed,
    BindFailed,
    SendFailed,
    ReceiveFailed,
    Timeout,
    InvalidAddress,
    MessageTooLarge,
    SequenceExhausted,
    NoResponseReceived,
} || marshal.MarshalError;

/// Maximum PFCP message size (based on typical MTU)
pub const MAX_MESSAGE_SIZE = 8192;

/// Default timeout for PFCP requests (in milliseconds)
pub const DEFAULT_TIMEOUT_MS = 5000;

/// Maximum number of retransmissions
pub const MAX_RETRANSMISSIONS = 3;

/// Sequence number manager
pub const SequenceManager = struct {
    value: u24,
    mutex: std.Thread.Mutex,

    pub fn init() SequenceManager {
        return .{
            .value = 0,
            .mutex = .{},
        };
    }

    /// Get next sequence number (thread-safe)
    pub fn next(self: *SequenceManager) NetError!u24 {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.value == std.math.maxInt(u24)) {
            self.value = 0;
        } else {
            self.value += 1;
        }
        return self.value;
    }

    /// Get current sequence number without incrementing
    pub fn getCurrent(self: *const SequenceManager) u24 {
        return self.value;
    }
};

/// Pending request tracking
pub const PendingRequest = struct {
    sequence_number: u24,
    message_data: []u8,
    destination: net.Address,
    sent_time: i64,
    retransmit_count: u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, seq: u24, data: []const u8, dest: net.Address) !PendingRequest {
        const message_copy = try allocator.alloc(u8, data.len);
        @memcpy(message_copy, data);

        return .{
            .sequence_number = seq,
            .message_data = message_copy,
            .destination = dest,
            .sent_time = std.time.milliTimestamp(),
            .retransmit_count = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *PendingRequest) void {
        self.allocator.free(self.message_data);
    }

    pub fn shouldRetransmit(self: *const PendingRequest, timeout_ms: i64) bool {
        const now = std.time.milliTimestamp();
        return (now - self.sent_time) > timeout_ms and self.retransmit_count < MAX_RETRANSMISSIONS;
    }

    pub fn isExpired(self: *const PendingRequest, timeout_ms: i64) bool {
        const now = std.time.milliTimestamp();
        return self.retransmit_count >= MAX_RETRANSMISSIONS and (now - self.sent_time) > timeout_ms;
    }
};

/// PFCP UDP Socket wrapper
pub const PfcpSocket = struct {
    socket: std.posix.socket_t,
    local_address: net.Address,
    allocator: Allocator,
    seq_manager: SequenceManager,
    pending_requests: std.ArrayList(PendingRequest),

    pub fn init(allocator: Allocator, bind_address: net.Address) !PfcpSocket {
        const sock = try std.posix.socket(
            bind_address.any.family,
            std.posix.SOCK.DGRAM,
            std.posix.IPPROTO.UDP,
        );
        errdefer std.posix.close(sock);

        // Set socket options
        try std.posix.setsockopt(
            sock,
            std.posix.SOL.SOCKET,
            std.posix.SO.REUSEADDR,
            &std.mem.toBytes(@as(c_int, 1)),
        );

        // Bind socket
        try std.posix.bind(sock, &bind_address.any, bind_address.getOsSockLen());

        return .{
            .socket = sock,
            .local_address = bind_address,
            .allocator = allocator,
            .seq_manager = SequenceManager.init(),
            .pending_requests = std.ArrayList(PendingRequest).init(allocator),
        };
    }

    pub fn deinit(self: *PfcpSocket) void {
        for (self.pending_requests.items) |*req| {
            req.deinit();
        }
        self.pending_requests.deinit();
        std.posix.close(self.socket);
    }

    /// Send raw data to a destination
    pub fn sendTo(self: *PfcpSocket, data: []const u8, destination: net.Address) !usize {
        const sent = try std.posix.sendto(
            self.socket,
            data,
            0,
            &destination.any,
            destination.getOsSockLen(),
        );
        return sent;
    }

    /// Receive raw data from socket
    pub fn receiveFrom(self: *PfcpSocket, buffer: []u8) !struct { data: []u8, address: net.Address } {
        var src_addr: net.Address = undefined;
        var src_addr_len: std.posix.socklen_t = @sizeOf(net.Address);

        const received = try std.posix.recvfrom(
            self.socket,
            buffer,
            0,
            &src_addr.any,
            &src_addr_len,
        );

        return .{
            .data = buffer[0..received],
            .address = src_addr,
        };
    }

    /// Send a PFCP message with automatic sequence number assignment
    pub fn sendMessage(
        self: *PfcpSocket,
        message_type: types.MessageType,
        seid: ?u64,
        payload: []const u8,
        destination: net.Address,
    ) !u24 {
        var buffer: [MAX_MESSAGE_SIZE]u8 = undefined;
        var writer = marshal.Writer.init(&buffer);

        const seq_num = try self.seq_manager.next();
        const has_seid = seid != null;

        // Write PFCP header
        // Byte 0: Version (4 bits) + spare + MP + S
        const version_byte: u8 = (types.PFCP_VERSION << 4) | (if (has_seid) 0x01 else 0x00);
        try writer.writeByte(version_byte);

        // Byte 1: Message type
        try writer.writeByte(@intFromEnum(message_type));

        // Calculate message length (will update later)
        const length_pos = writer.pos;
        try writer.writeU16(0); // Placeholder for length

        // Write SEID if present
        if (seid) |s| {
            try writer.writeU64(s);
        }

        // Write sequence number
        try writer.writeU24(seq_num);

        // Write spare byte
        try writer.writeByte(0);

        // Write payload
        try writer.writeBytes(payload);

        // Update length field (length excludes first 4 bytes)
        const message_length: u16 = @intCast(writer.pos - 4);
        std.mem.writeInt(u16, buffer[length_pos..][0..2], message_length, .big);

        // Send message
        const data_to_send = writer.getWritten();
        _ = try self.sendTo(data_to_send, destination);

        // Track pending request for retransmission
        const pending = try PendingRequest.init(self.allocator, seq_num, data_to_send, destination);
        try self.pending_requests.append(pending);

        return seq_num;
    }

    /// Receive and parse a PFCP message
    pub fn receiveMessage(self: *PfcpSocket, buffer: []u8) !struct {
        message_type: types.MessageType,
        seid: ?u64,
        sequence_number: u24,
        payload: []const u8,
        source: net.Address,
    } {
        const result = try self.receiveFrom(buffer);
        var reader = marshal.Reader.init(result.data);

        // Parse PFCP header
        const version_byte = try reader.readByte();
        const version: u4 = @truncate(version_byte >> 4);
        if (version != types.PFCP_VERSION) {
            return NetError.InvalidVersion;
        }

        const has_seid = (version_byte & 0x01) != 0;

        const message_type_val = try reader.readByte();
        const message_type: types.MessageType = @enumFromInt(message_type_val);

        const message_length = try reader.readU16();
        _ = message_length; // TODO: validate length

        // Read SEID if present
        const seid: ?u64 = if (has_seid) try reader.readU64() else null;

        // Read sequence number
        const sequence_number = try reader.readU24();

        // Skip spare byte
        _ = try reader.readByte();

        // Rest is payload
        const payload_start = reader.pos;
        const payload = result.data[payload_start..];

        // Remove corresponding pending request if this is a response
        self.removePendingRequest(sequence_number);

        return .{
            .message_type = message_type,
            .seid = seid,
            .sequence_number = sequence_number,
            .payload = payload,
            .source = result.address,
        };
    }

    /// Remove a pending request by sequence number
    fn removePendingRequest(self: *PfcpSocket, seq_num: u24) void {
        var i: usize = 0;
        while (i < self.pending_requests.items.len) {
            if (self.pending_requests.items[i].sequence_number == seq_num) {
                var req = self.pending_requests.orderedRemove(i);
                req.deinit();
                return;
            }
            i += 1;
        }
    }

    /// Process retransmissions for pending requests
    pub fn processRetransmissions(self: *PfcpSocket, timeout_ms: i64) !void {
        var i: usize = 0;
        while (i < self.pending_requests.items.len) {
            var req = &self.pending_requests.items[i];

            if (req.isExpired(timeout_ms)) {
                // Remove expired request
                var expired = self.pending_requests.orderedRemove(i);
                expired.deinit();
                continue;
            }

            if (req.shouldRetransmit(timeout_ms)) {
                // Retransmit
                _ = try self.sendTo(req.message_data, req.destination);
                req.sent_time = std.time.milliTimestamp();
                req.retransmit_count += 1;
            }

            i += 1;
        }
    }

    /// Wait for a specific response with timeout
    pub fn waitForResponse(
        self: *PfcpSocket,
        seq_num: u24,
        buffer: []u8,
        timeout_ms: i64,
    ) !struct {
        message_type: types.MessageType,
        seid: ?u64,
        sequence_number: u24,
        payload: []const u8,
        source: net.Address,
    } {
        const start_time = std.time.milliTimestamp();

        while (true) {
            const elapsed = std.time.milliTimestamp() - start_time;
            if (elapsed > timeout_ms) {
                return NetError.Timeout;
            }

            // Set socket timeout for receive
            const remaining_ms = timeout_ms - elapsed;
            const tv = std.posix.timeval{
                .tv_sec = @intCast(@divFloor(remaining_ms, 1000)),
                .tv_usec = @intCast(@mod(remaining_ms, 1000) * 1000),
            };
            try std.posix.setsockopt(
                self.socket,
                std.posix.SOL.SOCKET,
                std.posix.SO.RCVTIMEO,
                &std.mem.toBytes(tv),
            );

            const msg = self.receiveMessage(buffer) catch |err| {
                if (err == error.WouldBlock) {
                    continue;
                }
                return err;
            };

            if (msg.sequence_number == seq_num) {
                return msg;
            }
            // Otherwise, discard and continue waiting
        }
    }
};

/// PFCP Connection/Association manager
pub const PfcpConnection = struct {
    socket: *PfcpSocket,
    remote_address: net.Address,
    remote_node_id: ?[]const u8,
    local_seid: ?u64,
    remote_seid: ?u64,
    associated: bool,
    allocator: Allocator,

    pub fn init(allocator: Allocator, socket: *PfcpSocket, remote_addr: net.Address) PfcpConnection {
        return .{
            .socket = socket,
            .remote_address = remote_addr,
            .remote_node_id = null,
            .local_seid = null,
            .remote_seid = null,
            .associated = false,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *PfcpConnection) void {
        if (self.remote_node_id) |node_id| {
            self.allocator.free(node_id);
        }
    }

    /// Send a message on this connection
    pub fn sendMessage(
        self: *PfcpConnection,
        message_type: types.MessageType,
        payload: []const u8,
    ) !u24 {
        const seid = if (message_type.hasSession()) self.remote_seid else null;
        return try self.socket.sendMessage(message_type, seid, payload, self.remote_address);
    }

    /// Send a message and wait for response
    pub fn sendAndWaitResponse(
        self: *PfcpConnection,
        message_type: types.MessageType,
        payload: []const u8,
        buffer: []u8,
        timeout_ms: i64,
    ) !struct {
        message_type: types.MessageType,
        seid: ?u64,
        sequence_number: u24,
        payload: []const u8,
        source: net.Address,
    } {
        const seq_num = try self.sendMessage(message_type, payload);
        return try self.socket.waitForResponse(seq_num, buffer, timeout_ms);
    }

    /// Mark association as established
    pub fn markAssociated(self: *PfcpConnection, remote_seid: ?u64) void {
        self.associated = true;
        self.remote_seid = remote_seid;
    }

    /// Check if association is established
    pub fn isAssociated(self: *const PfcpConnection) bool {
        return self.associated;
    }
};

// Tests
test "SequenceManager basic operations" {
    var seq_mgr = SequenceManager.init();

    const seq1 = try seq_mgr.next();
    try std.testing.expectEqual(@as(u24, 1), seq1);

    const seq2 = try seq_mgr.next();
    try std.testing.expectEqual(@as(u24, 2), seq2);

    const seq3 = try seq_mgr.next();
    try std.testing.expectEqual(@as(u24, 3), seq3);
}

test "SequenceManager wraparound" {
    var seq_mgr = SequenceManager.init();
    seq_mgr.value = std.math.maxInt(u24) - 1;

    const seq1 = try seq_mgr.next();
    try std.testing.expectEqual(std.math.maxInt(u24), seq1);

    const seq2 = try seq_mgr.next();
    try std.testing.expectEqual(@as(u24, 0), seq2);
}

test "PfcpSocket bind to localhost" {
    const allocator = std.testing.allocator;

    const bind_addr = try net.Address.parseIp("127.0.0.1", types.PFCP_PORT);
    var socket = try PfcpSocket.init(allocator, bind_addr);
    defer socket.deinit();

    try std.testing.expect(socket.socket > 0);
    try std.testing.expectEqual(bind_addr.getPort(), socket.local_address.getPort());
}

test "PfcpSocket send and receive" {
    const allocator = std.testing.allocator;

    // Create two sockets
    const bind_addr1 = try net.Address.parseIp("127.0.0.1", 8805);
    const bind_addr2 = try net.Address.parseIp("127.0.0.1", 8806);

    var socket1 = try PfcpSocket.init(allocator, bind_addr1);
    defer socket1.deinit();

    var socket2 = try PfcpSocket.init(allocator, bind_addr2);
    defer socket2.deinit();

    // Send from socket1 to socket2
    const test_data = "Hello PFCP!";
    _ = try socket1.sendTo(test_data, bind_addr2);

    // Receive on socket2
    var buffer: [1024]u8 = undefined;
    const result = try socket2.receiveFrom(&buffer);

    try std.testing.expectEqualStrings(test_data, result.data);
}

test "Marshal PFCP header" {
    var buffer: [100]u8 = undefined;
    var writer = marshal.Writer.init(&buffer);

    // Write a simple PFCP header for Heartbeat Request (message type 1)
    const version_byte: u8 = (types.PFCP_VERSION << 4); // No SEID
    try writer.writeByte(version_byte);
    try writer.writeByte(@intFromEnum(types.MessageType.heartbeat_request));
    try writer.writeU16(4); // Length: 4 bytes (seq + spare)
    try writer.writeU24(12345); // Sequence number
    try writer.writeByte(0); // Spare

    const written = writer.getWritten();
    try std.testing.expectEqual(@as(usize, 8), written.len);

    // Parse it back
    var reader = marshal.Reader.init(written);
    const parsed_version = try reader.readByte();
    try std.testing.expectEqual(types.PFCP_VERSION, parsed_version >> 4);

    const parsed_msg_type = try reader.readByte();
    try std.testing.expectEqual(@as(u8, 1), parsed_msg_type);

    const parsed_length = try reader.readU16();
    try std.testing.expectEqual(@as(u16, 4), parsed_length);

    const parsed_seq = try reader.readU24();
    try std.testing.expectEqual(@as(u24, 12345), parsed_seq);
}
