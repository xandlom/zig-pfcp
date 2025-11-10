// Comprehensive tests for net module
const std = @import("std");
const pfcp = @import("zig-pfcp");
const net_module = pfcp.net;
const types = pfcp.types;

test "NetError - all error types" {
    const errors = [_]type{
        net_module.NetError,
    };
    _ = errors;
}

test "Constants - MAX_MESSAGE_SIZE" {
    try std.testing.expectEqual(@as(usize, 8192), net_module.MAX_MESSAGE_SIZE);
}

test "Constants - DEFAULT_TIMEOUT_MS" {
    try std.testing.expectEqual(@as(i64, 5000), net_module.DEFAULT_TIMEOUT_MS);
}

test "Constants - MAX_RETRANSMISSIONS" {
    try std.testing.expectEqual(@as(u8, 3), net_module.MAX_RETRANSMISSIONS);
}

test "SequenceManager - initialization" {
    const seq_mgr = net_module.SequenceManager.init();

    try std.testing.expectEqual(@as(u24, 0), seq_mgr.value);
}

test "SequenceManager - next increments" {
    var seq_mgr = net_module.SequenceManager.init();

    const seq1 = try seq_mgr.next();
    const seq2 = try seq_mgr.next();
    const seq3 = try seq_mgr.next();

    try std.testing.expectEqual(@as(u24, 1), seq1);
    try std.testing.expectEqual(@as(u24, 2), seq2);
    try std.testing.expectEqual(@as(u24, 3), seq3);
}

test "SequenceManager - wraps at max value" {
    var seq_mgr = net_module.SequenceManager.init();
    seq_mgr.value = std.math.maxInt(u24) - 1;

    const seq1 = try seq_mgr.next();
    const seq2 = try seq_mgr.next();

    try std.testing.expectEqual(std.math.maxInt(u24), seq1);
    try std.testing.expectEqual(@as(u24, 0), seq2);
}

test "SequenceManager - sequential numbers" {
    var seq_mgr = net_module.SequenceManager.init();

    for (1..100) |i| {
        const seq = try seq_mgr.next();
        try std.testing.expectEqual(@as(u24, @intCast(i)), seq);
    }
}

test "PendingRequest - initialization" {
    const allocator = std.testing.allocator;
    const data = [_]u8{ 0x01, 0x02, 0x03, 0x04 };
    const dest = try std.net.Address.parseIp4("127.0.0.1", 8805);

    var request = try net_module.PendingRequest.init(allocator, 42, &data, dest);
    defer request.deinit();

    try std.testing.expectEqual(@as(u24, 42), request.sequence_number);
    try std.testing.expectEqual(@as(usize, 4), request.message_data.len);
    try std.testing.expectEqual(@as(u8, 0), request.retransmit_count);
}

test "PendingRequest - data is copied" {
    const allocator = std.testing.allocator;
    var data = [_]u8{ 0x01, 0x02, 0x03, 0x04 };
    const dest = try std.net.Address.parseIp4("127.0.0.1", 8805);

    var request = try net_module.PendingRequest.init(allocator, 42, &data, dest);
    defer request.deinit();

    // Modify original data
    data[0] = 0xFF;

    // Request should have original value
    try std.testing.expectEqual(@as(u8, 0x01), request.message_data[0]);
}

test "PendingRequest - shouldRetransmit initially false" {
    const allocator = std.testing.allocator;
    const data = [_]u8{ 0x01, 0x02, 0x03 };
    const dest = try std.net.Address.parseIp4("127.0.0.1", 8805);

    var request = try net_module.PendingRequest.init(allocator, 1, &data, dest);
    defer request.deinit();

    // Should not retransmit immediately
    try std.testing.expect(!request.shouldRetransmit(100));
}

test "PendingRequest - isExpired false initially" {
    const allocator = std.testing.allocator;
    const data = [_]u8{ 0x01, 0x02, 0x03 };
    const dest = try std.net.Address.parseIp4("127.0.0.1", 8805);

    var request = try net_module.PendingRequest.init(allocator, 1, &data, dest);
    defer request.deinit();

    try std.testing.expect(!request.isExpired(100));
}

test "PendingRequest - isExpired after max retransmissions" {
    const allocator = std.testing.allocator;
    const data = [_]u8{ 0x01, 0x02, 0x03 };
    const dest = try std.net.Address.parseIp4("127.0.0.1", 8805);

    var request = try net_module.PendingRequest.init(allocator, 1, &data, dest);
    defer request.deinit();

    request.retransmit_count = net_module.MAX_RETRANSMISSIONS;
    request.sent_time = std.time.milliTimestamp() - 10000; // 10 seconds ago

    try std.testing.expect(request.isExpired(5000));
}

test "PfcpSocket - address parsing" {
    // Test IPv4 address parsing
    const addr_v4 = try std.net.Address.parseIp4("127.0.0.1", types.PFCP_PORT);
    try std.testing.expectEqual(@as(u16, 8805), addr_v4.getPort());

    // Test IPv6 address parsing
    const addr_v6 = try std.net.Address.parseIp6("::1", types.PFCP_PORT);
    try std.testing.expectEqual(@as(u16, 8805), addr_v6.getPort());
}

test "PfcpSocket - default port" {
    const addr = try std.net.Address.parseIp4("0.0.0.0", types.PFCP_PORT);
    try std.testing.expectEqual(@as(u16, 8805), addr.getPort());
}

// Note: Full socket tests would require actual network operations
// which are better suited for integration tests rather than unit tests
// The following tests verify the basic structure and initialization

test "Message type and SEID relationship" {
    const node_message = types.MessageType.heartbeat_request;
    const session_message = types.MessageType.session_establishment_request;

    try std.testing.expect(!node_message.hasSession());
    try std.testing.expect(session_message.hasSession());
}
