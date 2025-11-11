// Example: PFCP Session Server (UPF Simulator)
//
// This example demonstrates a PFCP server (UPF) that accepts
// association setup requests and session establishment requests using real UDP sockets.

const std = @import("std");
const pfcp = @import("zig-pfcp");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== PFCP Session Server (UPF Simulator) ===\n\n", .{});

    // Configuration
    const server_ip = "127.0.0.1";
    const server_port = 8806;

    std.debug.print("Configuration:\n", .{});
    std.debug.print("  Listening on: {s}:{d}\n\n", .{ server_ip, server_port });

    // Create and bind UDP socket
    std.debug.print("Step 1: Creating UDP socket and binding...\n", .{});
    const local_addr = try std.net.Address.parseIp(server_ip, server_port);
    var socket = try pfcp.net.PfcpSocket.init(allocator, local_addr);
    defer socket.deinit();
    std.debug.print("  Socket bound to {s}:{d}\n", .{ server_ip, server_port });
    std.debug.print("  Waiting for PFCP messages...\n\n", .{});

    // Server identity
    const server_addr_bytes = [_]u8{ 127, 0, 0, 1 };
    const recovery = pfcp.ie.RecoveryTimeStamp.fromUnixTime(std.time.timestamp());
    const node_id = pfcp.ie.NodeId.initIpv4(server_addr_bytes);

    // Session state
    var up_seid: ?u64 = null;
    var cp_seid: ?u64 = null;

    // Main server loop - handle 2 messages (association + session)
    var messages_handled: u32 = 0;
    while (messages_handled < 2) : (messages_handled += 1) {
        // Receive message
        var recv_buffer: [4096]u8 = undefined;
        const msg = try socket.receiveMessage(&recv_buffer);

        std.debug.print("Received message from {}\n", .{msg.source});
        std.debug.print("  Type: {s}\n", .{@tagName(msg.message_type)});
        std.debug.print("  Sequence: {d}\n", .{msg.sequence_number});
        if (msg.seid) |seid| {
            std.debug.print("  SEID: 0x{X:0>16}\n", .{seid});
        }

        switch (msg.message_type) {
            .association_setup_request => {
                std.debug.print("\nStep 2: Processing Association Setup Request...\n", .{});

                // Unmarshal request
                var reader = pfcp.marshal.Reader.init(msg.payload);
                const assoc_req = try pfcp.AssociationSetupRequest.unmarshal(&reader);

                std.debug.print("  Remote Node ID: ", .{});
                switch (assoc_req.node_id.id_type) {
                    .ipv4 => |ip| std.debug.print("IPv4 {d}.{d}.{d}.{d}\n", .{ ip[0], ip[1], ip[2], ip[3] }),
                    .ipv6 => std.debug.print("IPv6\n", .{}),
                    .fqdn => std.debug.print("FQDN\n", .{}),
                }
                std.debug.print("  Remote Recovery Time: {d}\n\n", .{assoc_req.recovery_time_stamp.timestamp});

                // Send Association Setup Response (Accepted)
                std.debug.print("Step 3: Sending Association Setup Response (Accepted)...\n", .{});
                const assoc_resp = pfcp.AssociationSetupResponse.accepted(node_id, recovery);

                // Marshal response
                var assoc_resp_buffer: [4096]u8 = undefined;
                var writer = pfcp.marshal.Writer.init(&assoc_resp_buffer);
                try assoc_resp.marshal(&writer);
                const assoc_resp_payload = writer.getWritten();

                // Send response
                _ = try socket.sendMessage(
                    pfcp.types.MessageType.association_setup_response,
                    null, // No SEID for node messages
                    assoc_resp_payload,
                    msg.source,
                );
                std.debug.print("  Sent Association Setup Response (seq: {d})\n", .{msg.sequence_number});
                std.debug.print("  Cause: Request Accepted\n", .{});
                std.debug.print("  Node ID: IPv4 127.0.0.1\n\n", .{});
            },

            .session_establishment_request => {
                std.debug.print("\nStep 4: Processing Session Establishment Request...\n", .{});

                // Unmarshal request
                var reader = pfcp.marshal.Reader.init(msg.payload);
                const session_req = try pfcp.SessionEstablishmentRequest.unmarshal(&reader);

                cp_seid = session_req.f_seid.seid;
                std.debug.print("  CP F-SEID: 0x{X:0>16}\n", .{session_req.f_seid.seid});
                std.debug.print("  CP F-SEID IPv4: ", .{});
                if (session_req.f_seid.ipv4_address) |ip| {
                    std.debug.print("{d}.{d}.{d}.{d}\n", .{ ip[0], ip[1], ip[2], ip[3] });
                } else {
                    std.debug.print("(not set)\n", .{});
                }

                // Allocate local SEID
                up_seid = 0xFEDCBA0987654321;
                std.debug.print("\nStep 5: Allocating local SEID...\n", .{});
                std.debug.print("  UP F-SEID: 0x{X:0>16}\n\n", .{up_seid.?});

                // Send Session Establishment Response (Accepted)
                std.debug.print("Step 6: Sending Session Establishment Response (Accepted)...\n", .{});
                const up_fseid = pfcp.ie.FSEID.initV4(up_seid.?, server_addr_bytes);
                const session_resp = pfcp.SessionEstablishmentResponse.accepted(node_id, up_fseid);

                // Marshal response
                var session_resp_buffer: [4096]u8 = undefined;
                var writer = pfcp.marshal.Writer.init(&session_resp_buffer);
                try session_resp.marshal(&writer);
                const session_resp_payload = writer.getWritten();

                // Send response (with CP SEID from request)
                _ = try socket.sendMessage(
                    pfcp.types.MessageType.session_establishment_response,
                    cp_seid.?, // Use CP SEID as remote SEID
                    session_resp_payload,
                    msg.source,
                );
                std.debug.print("  Sent Session Establishment Response (seq: {d})\n", .{msg.sequence_number});
                std.debug.print("  Cause: Request Accepted\n", .{});
                std.debug.print("  UP F-SEID: 0x{X:0>16}\n", .{up_seid.?});
                std.debug.print("  UP F-SEID IPv4: 127.0.0.1\n\n", .{});

                std.debug.print("Step 7: Session context created\n", .{});
                std.debug.print("  Local SEID (UP):  0x{X:0>16}\n", .{up_seid.?});
                std.debug.print("  Remote SEID (CP): 0x{X:0>16}\n\n", .{cp_seid.?});
            },

            else => {
                std.debug.print("  Unhandled message type: {s}\n\n", .{@tagName(msg.message_type)});
            },
        }
    }

    std.debug.print("=== UPF Simulator completed successfully! ===\n", .{});
    std.debug.print("\nSession Summary:\n", .{});
    if (up_seid) |seid| {
        std.debug.print("  Local SEID (UP):  0x{X:0>16}\n", .{seid});
    }
    if (cp_seid) |seid| {
        std.debug.print("  Remote SEID (CP): 0x{X:0>16}\n", .{seid});
    }
    std.debug.print("\nNote: Session is now active. In a real UPF:\n", .{});
    std.debug.print("  - Would continue listening for messages\n", .{});
    std.debug.print("  - Would handle heartbeats\n", .{});
    std.debug.print("  - Would process session modifications\n", .{});
    std.debug.print("  - Would enforce PDR/FAR/QER/URR rules\n", .{});
    std.debug.print("  - Would send session reports to SMF\n", .{});
    std.debug.print("  - Would handle session deletion\n\n", .{});
}
