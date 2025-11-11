// Example: PFCP Session Client (SMF Simulator)
//
// This example demonstrates a PFCP client (SMF) that establishes
// an association with a UPF and creates a PFCP session using real UDP sockets.

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
    const local_addr = try std.net.Address.parseIp(local_ip, local_port);
    var socket = try pfcp.net.PfcpSocket.init(allocator, local_addr);
    defer socket.deinit();
    std.debug.print("  Socket bound to {s}:{d}\n\n", .{ local_ip, local_port });

    // Prepare remote address
    const remote_addr = try std.net.Address.parseIp(remote_ip, remote_port);

    // Step 2: Send Association Setup Request
    std.debug.print("Step 2: Sending Association Setup Request...\n", .{});
    const recovery = pfcp.ie.RecoveryTimeStamp.fromUnixTime(std.time.timestamp());
    const local_addr_bytes = [_]u8{ 127, 0, 0, 1 };
    const node_id = pfcp.ie.NodeId.initIpv4(local_addr_bytes);
    const assoc_req = pfcp.AssociationSetupRequest.init(node_id, recovery);

    // Marshal Association Setup Request
    var assoc_req_buffer: [4096]u8 = undefined;
    var writer = pfcp.marshal.Writer.init(&assoc_req_buffer);
    try assoc_req.marshal(&writer);
    const assoc_req_payload = writer.getWritten();

    // Send Association Setup Request
    const assoc_seq = try socket.sendMessage(
        pfcp.types.MessageType.association_setup_request,
        null, // No SEID for node messages
        assoc_req_payload,
        remote_addr,
    );
    std.debug.print("  Sent Association Setup Request (seq: {d})\n", .{assoc_seq});
    std.debug.print("  Node ID: IPv4 127.0.0.1\n", .{});
    std.debug.print("  Recovery Time: {d}\n\n", .{recovery.timestamp});

    // Step 3: Wait for Association Setup Response
    std.debug.print("Step 3: Waiting for Association Setup Response...\n", .{});
    var assoc_resp_buffer: [4096]u8 = undefined;
    const assoc_resp_msg = try socket.waitForResponse(
        assoc_seq,
        &assoc_resp_buffer,
        pfcp.net.DEFAULT_TIMEOUT_MS,
    );

    // Unmarshal Association Setup Response
    var assoc_resp_reader = pfcp.marshal.Reader.init(assoc_resp_msg.payload);
    const assoc_resp = try pfcp.AssociationSetupResponse.unmarshal(&assoc_resp_reader);

    if (assoc_resp.cause.cause.isAccepted()) {
        std.debug.print("  Association established successfully!\n", .{});
        std.debug.print("  Cause: Request Accepted\n", .{});
        std.debug.print("  Remote Node ID: ", .{});
        switch (assoc_resp.node_id.id_type) {
            .ipv4 => |ip| std.debug.print("IPv4 {d}.{d}.{d}.{d}\n", .{ ip[0], ip[1], ip[2], ip[3] }),
            .ipv6 => std.debug.print("IPv6\n", .{}),
            .fqdn => std.debug.print("FQDN\n", .{}),
        }
        std.debug.print("  Remote Recovery Time: {d}\n\n", .{assoc_resp.recovery_time_stamp.timestamp});
    } else {
        std.debug.print("  Association setup failed!\n", .{});
        std.debug.print("  Cause: {}\n\n", .{assoc_resp.cause.cause});
        return error.AssociationFailed;
    }

    // Step 4: Send Session Establishment Request
    std.debug.print("Step 4: Sending Session Establishment Request...\n", .{});
    const cp_seid: u64 = 0x1234567890ABCDEF;
    const cp_fseid = pfcp.ie.FSEID.initV4(cp_seid, local_addr_bytes);
    const session_req = pfcp.SessionEstablishmentRequest.init(node_id, cp_fseid);

    // Marshal Session Establishment Request
    var session_req_buffer: [4096]u8 = undefined;
    var session_writer = pfcp.marshal.Writer.init(&session_req_buffer);
    try session_req.marshal(&session_writer);
    const session_req_payload = session_writer.getWritten();

    // Send Session Establishment Request (with SEID = 0 for new session)
    const session_seq = try socket.sendMessage(
        pfcp.types.MessageType.session_establishment_request,
        0, // SEID is 0 for session establishment request
        session_req_payload,
        remote_addr,
    );
    std.debug.print("  Sent Session Establishment Request (seq: {d})\n", .{session_seq});
    std.debug.print("  CP F-SEID: 0x{X:0>16}\n", .{cp_seid});
    std.debug.print("  CP F-SEID IPv4: 127.0.0.1\n\n", .{});

    // Step 5: Wait for Session Establishment Response
    std.debug.print("Step 5: Waiting for Session Establishment Response...\n", .{});
    var session_resp_buffer: [4096]u8 = undefined;
    const session_resp_msg = try socket.waitForResponse(
        session_seq,
        &session_resp_buffer,
        pfcp.net.DEFAULT_TIMEOUT_MS,
    );

    // Unmarshal Session Establishment Response
    var session_resp_reader = pfcp.marshal.Reader.init(session_resp_msg.payload);
    const session_resp = try pfcp.SessionEstablishmentResponse.unmarshal(&session_resp_reader);

    if (session_resp.cause.cause.isAccepted()) {
        std.debug.print("  Session established successfully!\n", .{});
        std.debug.print("  Cause: Request Accepted\n", .{});
        if (session_resp.f_seid) |up_fseid| {
            std.debug.print("  UP F-SEID: 0x{X:0>16}\n", .{up_fseid.seid});
            std.debug.print("  UP F-SEID IPv4: ", .{});
            if (up_fseid.ipv4_address) |ip| {
                std.debug.print("{d}.{d}.{d}.{d}\n", .{ ip[0], ip[1], ip[2], ip[3] });
            } else {
                std.debug.print("(not set)\n", .{});
            }
        }
        std.debug.print("  Remote SEID: 0x{X:0>16}\n\n", .{session_resp_msg.seid.?});
    } else {
        std.debug.print("  Session establishment failed!\n", .{});
        std.debug.print("  Cause: {}\n\n", .{session_resp.cause.cause});
        return error.SessionEstablishmentFailed;
    }

    std.debug.print("=== SMF Simulator completed successfully! ===\n", .{});
    std.debug.print("\nSession Summary:\n", .{});
    std.debug.print("  Local SEID (CP):  0x{X:0>16}\n", .{cp_seid});
    std.debug.print("  Remote SEID (UP): 0x{X:0>16}\n", .{session_resp_msg.seid.?});
    std.debug.print("\nNote: Session is now active. In a real SMF:\n", .{});
    std.debug.print("  - Would handle heartbeats\n", .{});
    std.debug.print("  - Would send session modifications (PDR/FAR/QER/URR)\n", .{});
    std.debug.print("  - Would handle session reports from UPF\n", .{});
    std.debug.print("  - Would eventually send session deletion\n\n", .{});
}
