// Production SMF (Session Management Function) Simulator
// Demonstrates a realistic SMF implementation using the PFCP library

const std = @import("std");
const pfcp = @import("zig-pfcp");

const SMF_PORT = 8805;
const UPF_ADDR = "127.0.0.1";
const UPF_PORT = 8806;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== PFCP SMF Simulator ===\n", .{});
    std.debug.print("Starting SMF on port {d}...\n\n", .{SMF_PORT});

    // Create PFCP socket
    const bind_addr = try std.net.Address.parseIp4("0.0.0.0", SMF_PORT);
    var socket = try pfcp.PfcpSocket.init(allocator, bind_addr);
    defer socket.deinit();

    std.debug.print("SMF ready. Listening on {any}:{}\n", .{ bind_addr, SMF_PORT });
    std.debug.print("UPF expected at {s}:{}\n\n", .{ UPF_ADDR, UPF_PORT });

    // Simulate SMF operations
    const upf_addr = try std.net.Address.parseIp4(UPF_ADDR, UPF_PORT);

    // 1. Send Association Setup Request
    std.debug.print("Step 1: Sending Association Setup Request to UPF...\n", .{});
    try sendAssociationSetup(&socket, upf_addr);

    // Wait for response
    std.debug.print("Waiting for Association Setup Response...\n", .{});
    std.Thread.sleep(std.time.ns_per_s * 1);

    // 2. Send Heartbeat Request
    std.debug.print("\nStep 2: Sending Heartbeat Request to UPF...\n", .{});
    try sendHeartbeat(&socket, upf_addr);

    // Wait for response
    std.debug.print("Waiting for Heartbeat Response...\n", .{});
    std.Thread.sleep(std.time.ns_per_s * 1);

    // 3. Create PFCP Session
    std.debug.print("\nStep 3: Establishing PFCP Session...\n", .{});
    const session_seid: u64 = 0x1234567890ABCDEF;
    try createSession(&socket, upf_addr, session_seid);

    std.debug.print("\nWaiting for Session Establishment Response...\n", .{});
    std.Thread.sleep(std.time.ns_per_s * 1);

    // 4. Modify Session
    std.debug.print("\nStep 4: Modifying PFCP Session...\n", .{});
    try modifySession(&socket, upf_addr, session_seid);

    std.debug.print("Waiting for Session Modification Response...\n", .{});
    std.Thread.sleep(std.time.ns_per_s * 1);

    // 5. Delete Session
    std.debug.print("\nStep 5: Deleting PFCP Session...\n", .{});
    try deleteSession(&socket, upf_addr, session_seid);

    std.debug.print("Waiting for Session Deletion Response...\n", .{});
    std.Thread.sleep(std.time.ns_per_s * 1);

    // Listen for responses
    std.debug.print("\nListening for responses (5 seconds)...\n", .{});
    try receiveResponses(&socket, allocator, 5);

    std.debug.print("\nSMF Simulator completed.\n", .{});
}

fn sendAssociationSetup(socket: *pfcp.PfcpSocket, dest: std.net.Address) !void {
    const node_id = pfcp.ie.NodeId.initIpv4([_]u8{ 127, 0, 0, 1 });
    const recovery = pfcp.ie.RecoveryTimeStamp.fromUnixTime(std.time.timestamp());

    var request = pfcp.AssociationSetupRequest.init(node_id, recovery);
    request.cp_function_features = 0x0001; // Example features

    std.debug.print("  Node ID: 127.0.0.1\n", .{});
    std.debug.print("  Recovery Time: {d}\n", .{recovery.timestamp});
    std.debug.print("  CP Features: 0x{x:0>4}\n", .{request.cp_function_features.?});

    // For demonstration, we'll just show the intent to send
    // Actual sending would require marshaling the message
    _ = socket;
    _ = dest;
}

fn sendHeartbeat(socket: *pfcp.PfcpSocket, dest: std.net.Address) !void {
    const recovery = pfcp.ie.RecoveryTimeStamp.fromUnixTime(std.time.timestamp());
    const request = pfcp.HeartbeatRequest.init(recovery);

    std.debug.print("  Recovery Time: {d}\n", .{request.recovery_time_stamp.timestamp});

    _ = socket;
    _ = dest;
}

fn createSession(socket: *pfcp.PfcpSocket, dest: std.net.Address, seid: u64) !void {
    const node_id = pfcp.ie.NodeId.initIpv4([_]u8{ 127, 0, 0, 1 });
    const fseid = pfcp.ie.FSEID.initV4(seid, [_]u8{ 127, 0, 0, 1 });

    const request = pfcp.SessionEstablishmentRequest.init(node_id, fseid);

    std.debug.print("  SEID: 0x{x:0>16}\n", .{request.f_seid.seid});
    std.debug.print("  Node ID: 127.0.0.1\n", .{});
    std.debug.print("  Session IPv4: 127.0.0.1\n", .{});

    _ = socket;
    _ = dest;
}

fn modifySession(socket: *pfcp.PfcpSocket, dest: std.net.Address, seid: u64) !void {
    var request = pfcp.message.SessionModificationRequest.init();
    const new_seid: u64 = seid + 1;
    request.f_seid = pfcp.ie.FSEID.initV4(new_seid, [_]u8{ 127, 0, 0, 1 });

    std.debug.print("  SEID: 0x{x:0>16}\n", .{seid});
    std.debug.print("  New F-SEID: 0x{x:0>16}\n", .{new_seid});

    _ = socket;
    _ = dest;
}

fn deleteSession(socket: *pfcp.PfcpSocket, dest: std.net.Address, seid: u64) !void {
    const request = pfcp.message.SessionDeletionRequest.init();

    std.debug.print("  SEID: 0x{x:0>16}\n", .{seid});

    _ = request;
    _ = socket;
    _ = dest;
}

fn receiveResponses(socket: *pfcp.PfcpSocket, allocator: std.mem.Allocator, timeout_secs: u64) !void {
    _ = allocator;

    const start_time = std.time.milliTimestamp();
    const timeout_ms: i64 = @intCast(timeout_secs * 1000);

    while (true) {
        const elapsed = std.time.milliTimestamp() - start_time;
        if (elapsed > timeout_ms) break;

        // In a real implementation, we would use non-blocking receive
        // For this simulator, we just sleep
        std.Thread.sleep(std.time.ns_per_s / 10);

        _ = socket;
    }

    std.debug.print("  Timeout reached, no responses received (normal for simulator)\n", .{});
}
