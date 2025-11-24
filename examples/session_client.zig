// Example: PFCP Session Client (SMF Simulator)
//
// This example demonstrates a PFCP client (SMF) that uses real UDP sockets
// to communicate with a UPF simulator.

const std = @import("std");
const pfcp = @import("zig-pfcp");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== PFCP Session Client (SMF Simulator) ===\n\n", .{});

    // Configuration
    const local_ip = "127.0.0.1";
    const local_port = 8805;
    const remote_ip = "127.0.0.1";
    const remote_port = 8806;

    std.debug.print("Configuration:\n", .{});
    std.debug.print("  Local (SMF):  {s}:{d}\n", .{ local_ip, local_port });
    std.debug.print("  Remote (UPF): {s}:{d}\n\n", .{ remote_ip, remote_port });

    // Create and bind UDP socket
    std.debug.print("Step 1: Creating UDP socket...\n", .{});
    const local_addr = try std.net.Address.parseIp4(local_ip, local_port);
    var socket = try pfcp.PfcpSocket.init(allocator, local_addr);
    defer socket.deinit();
    std.debug.print("  Socket bound to {s}:{d}\n\n", .{ local_ip, local_port });

    // Prepare remote address
    const remote_addr = try std.net.Address.parseIp4(remote_ip, remote_port);

    // Step 2: Build Association Setup Request
    std.debug.print("Step 2: Building Association Setup Request...\n", .{});
    const recovery = pfcp.ie.RecoveryTimeStamp.fromUnixTime(std.time.timestamp());
    const local_addr_bytes = [_]u8{ 127, 0, 0, 1 };
    const node_id = pfcp.ie.NodeId.initIpv4(local_addr_bytes);
    const assoc_req = pfcp.AssociationSetupRequest.init(node_id, recovery);
    std.debug.print("  Node ID: IPv4 127.0.0.1\n", .{});
    std.debug.print("  Recovery Time: {d}\n", .{recovery.timestamp});

    // Create simple message payload (for demonstration)
    var assoc_payload: [256]u8 = undefined;
    const assoc_msg = try std.fmt.bufPrint(&assoc_payload, "ASSOC_REQ:{d}", .{recovery.timestamp});

    // Send Association Setup Request using real UDP
    const assoc_seq = try socket.sendMessage(
        pfcp.types.MessageType.association_setup_request,
        null,
        assoc_msg,
        remote_addr,
    );
    std.debug.print("  Sent via UDP (seq: {d}, {d} bytes)\n\n", .{ assoc_seq, assoc_msg.len });

    // Step 3: Wait for Association Setup Response
    std.debug.print("Step 3: Waiting for Association Setup Response via UDP...\n", .{});
    var resp_buffer: [4096]u8 = undefined;
    const assoc_resp = socket.waitForResponse(
        assoc_seq,
        &resp_buffer,
        pfcp.net.DEFAULT_TIMEOUT_MS,
    ) catch |err| {
        std.debug.print("  Error: {}\n", .{err});
        std.debug.print("  (Make sure UPF simulator is running on {s}:{d})\n\n", .{ remote_ip, remote_port });
        return err;
    };

    std.debug.print("  Received response from {any}\n", .{assoc_resp.source});
    std.debug.print("  Message type: {s}\n", .{@tagName(assoc_resp.message_type)});
    std.debug.print("  Sequence: {d}\n", .{assoc_resp.sequence_number});
    std.debug.print("  Payload: {s}\n", .{assoc_resp.payload});
    std.debug.print("  Association established!\n\n", .{});

    // Step 4: Build Session Establishment Request
    std.debug.print("Step 4: Building Session Establishment Request...\n", .{});
    const cp_seid: u64 = 0x1234567890ABCDEF;
    const cp_fseid = pfcp.ie.FSEID.initV4(cp_seid, local_addr_bytes);
    const session_req = pfcp.SessionEstablishmentRequest.init(node_id, cp_fseid);
    std.debug.print("  CP F-SEID: 0x{X:0>16}\n", .{cp_seid});

    // Create session message payload
    var session_payload: [256]u8 = undefined;
    const session_msg = try std.fmt.bufPrint(&session_payload, "SESSION_REQ:SEID={X}", .{cp_seid});

    // Send Session Establishment Request
    const session_seq = try socket.sendMessage(
        pfcp.types.MessageType.session_establishment_request,
        0, // SEID is 0 for new session
        session_msg,
        remote_addr,
    );
    std.debug.print("  Sent via UDP (seq: {d}, {d} bytes)\n\n", .{ session_seq, session_msg.len });

    // Step 5: Wait for Session Establishment Response
    std.debug.print("Step 5: Waiting for Session Establishment Response via UDP...\n", .{});
    const session_resp = try socket.waitForResponse(
        session_seq,
        &resp_buffer,
        pfcp.net.DEFAULT_TIMEOUT_MS,
    );

    std.debug.print("  Received response from {any}\n", .{session_resp.source});
    std.debug.print("  Message type: {s}\n", .{@tagName(session_resp.message_type)});
    std.debug.print("  Sequence: {d}\n", .{session_resp.sequence_number});
    if (session_resp.seid) |seid| {
        std.debug.print("  Remote SEID: 0x{X:0>16}\n", .{seid});
    }
    std.debug.print("  Payload: {s}\n", .{session_resp.payload});
    std.debug.print("  Session established!\n\n", .{});

    std.debug.print("=== SMF Simulator completed successfully! ===\n", .{});
    std.debug.print("\nDemonstrated:\n", .{});
    std.debug.print("  ✓ Real UDP socket communication\n", .{});
    std.debug.print("  ✓ PfcpSocket send/receive operations\n", .{});
    std.debug.print("  ✓ Sequence number management\n", .{});
    std.debug.print("  ✓ Message type handling\n", .{});
    std.debug.print("  ✓ SEID handling for session messages\n", .{});
    std.debug.print("  ✓ Request/response matching with timeouts\n\n", .{});

    _ = assoc_req;
    _ = session_req;
}
