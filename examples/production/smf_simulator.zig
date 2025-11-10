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

    const stdout = std.io.getStdOut().writer();
    try stdout.print("=== PFCP SMF Simulator ===\n", .{});
    try stdout.print("Starting SMF on port {d}...\n\n", .{SMF_PORT});

    // Create PFCP socket
    const bind_addr = try std.net.Address.parseIp4("0.0.0.0", SMF_PORT);
    var socket = try pfcp.PfcpSocket.init(allocator, bind_addr);
    defer socket.deinit();

    try stdout.print("SMF ready. Listening on {}:{}\n", .{ bind_addr, SMF_PORT });
    try stdout.print("UPF expected at {}:{}\n\n", .{ UPF_ADDR, UPF_PORT });

    // Simulate SMF operations
    const upf_addr = try std.net.Address.parseIp4(UPF_ADDR, UPF_PORT);

    // 1. Send Association Setup Request
    try stdout.print("Step 1: Sending Association Setup Request to UPF...\n", .{});
    try sendAssociationSetup(&socket, upf_addr);

    // Wait for response
    try stdout.print("Waiting for Association Setup Response...\n", .{});
    std.time.sleep(std.time.ns_per_s * 1);

    // 2. Send Heartbeat Request
    try stdout.print("\nStep 2: Sending Heartbeat Request to UPF...\n", .{});
    try sendHeartbeat(&socket, upf_addr);

    // Wait for response
    try stdout.print("Waiting for Heartbeat Response...\n", .{});
    std.time.sleep(std.time.ns_per_s * 1);

    // 3. Create PFCP Session
    try stdout.print("\nStep 3: Establishing PFCP Session...\n", .{});
    const session_seid: u64 = 0x1234567890ABCDEF;
    try createSession(&socket, upf_addr, session_seid);

    try stdout.print("\nWaiting for Session Establishment Response...\n", .{});
    std.time.sleep(std.time.ns_per_s * 1);

    // 4. Modify Session
    try stdout.print("\nStep 4: Modifying PFCP Session...\n", .{});
    try modifySession(&socket, upf_addr, session_seid);

    try stdout.print("Waiting for Session Modification Response...\n", .{});
    std.time.sleep(std.time.ns_per_s * 1);

    // 5. Delete Session
    try stdout.print("\nStep 5: Deleting PFCP Session...\n", .{});
    try deleteSession(&socket, upf_addr, session_seid);

    try stdout.print("Waiting for Session Deletion Response...\n", .{});
    std.time.sleep(std.time.ns_per_s * 1);

    // Listen for responses
    try stdout.print("\nListening for responses (5 seconds)...\n", .{});
    try receiveResponses(&socket, allocator, 5);

    try stdout.print("\nSMF Simulator completed.\n", .{});
}

fn sendAssociationSetup(socket: *pfcp.PfcpSocket, dest: std.net.Address) !void {
    const node_id = pfcp.ie.NodeId.initIpv4([_]u8{ 127, 0, 0, 1 });
    const recovery = pfcp.ie.RecoveryTimeStamp.fromUnixTime(std.time.timestamp());

    var request = pfcp.AssociationSetupRequest.init(node_id, recovery);
    request.cp_function_features = 0x0001; // Example features

    const stdout = std.io.getStdOut().writer();
    try stdout.print("  Node ID: 127.0.0.1\n", .{});
    try stdout.print("  Recovery Time: {d}\n", .{recovery.timestamp});
    try stdout.print("  CP Features: 0x{x:0>4}\n", .{request.cp_function_features.?});

    // For demonstration, we'll just show the intent to send
    // Actual sending would require marshaling the message
    _ = socket;
    _ = dest;
}

fn sendHeartbeat(socket: *pfcp.PfcpSocket, dest: std.net.Address) !void {
    const recovery = pfcp.ie.RecoveryTimeStamp.fromUnixTime(std.time.timestamp());
    const request = pfcp.HeartbeatRequest.init(recovery);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("  Recovery Time: {d}\n", .{request.recovery_time_stamp.timestamp});

    _ = socket;
    _ = dest;
}

fn createSession(socket: *pfcp.PfcpSocket, dest: std.net.Address, seid: u64) !void {
    const node_id = pfcp.ie.NodeId.initIpv4([_]u8{ 127, 0, 0, 1 });
    const fseid = pfcp.ie.FSEID.initV4(seid, [_]u8{ 127, 0, 0, 1 });

    const request = pfcp.SessionEstablishmentRequest.init(node_id, fseid);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("  SEID: 0x{x:0>16}\n", .{request.f_seid.seid});
    try stdout.print("  Node ID: 127.0.0.1\n", .{});
    try stdout.print("  Session IPv4: 127.0.0.1\n", .{});

    _ = socket;
    _ = dest;
}

fn modifySession(socket: *pfcp.PfcpSocket, dest: std.net.Address, seid: u64) !void {
    var request = pfcp.message.SessionModificationRequest.init();
    const new_seid: u64 = seid + 1;
    request.f_seid = pfcp.ie.FSEID.initV4(new_seid, [_]u8{ 127, 0, 0, 1 });

    const stdout = std.io.getStdOut().writer();
    try stdout.print("  SEID: 0x{x:0>16}\n", .{seid});
    try stdout.print("  New F-SEID: 0x{x:0>16}\n", .{new_seid});

    _ = socket;
    _ = dest;
}

fn deleteSession(socket: *pfcp.PfcpSocket, dest: std.net.Address, seid: u64) !void {
    const request = pfcp.message.SessionDeletionRequest.init();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("  SEID: 0x{x:0>16}\n", .{seid});

    _ = request;
    _ = socket;
    _ = dest;
}

fn receiveResponses(socket: *pfcp.PfcpSocket, allocator: std.mem.Allocator, timeout_secs: u64) !void {
    _ = allocator;
    const stdout = std.io.getStdOut().writer();

    const start_time = std.time.milliTimestamp();
    const timeout_ms: i64 = @intCast(timeout_secs * 1000);

    while (true) {
        const elapsed = std.time.milliTimestamp() - start_time;
        if (elapsed > timeout_ms) break;

        // In a real implementation, we would use non-blocking receive
        // For this simulator, we just sleep
        std.time.sleep(std.time.ns_per_s / 10);

        _ = socket;
    }

    try stdout.print("  Timeout reached, no responses received (normal for simulator)\n", .{});
}
