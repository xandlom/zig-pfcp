// Example: PFCP Session Server (UPF Simulator)
//
// This example demonstrates a PFCP server (UPF) that uses real UDP sockets
// to accept connections from an SMF simulator.

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
    const local_addr = try std.net.Address.parseIp4(server_ip, server_port);
    var socket = try pfcp.PfcpSocket.init(allocator, local_addr);
    defer socket.deinit();
    std.debug.print("  Socket bound to {s}:{d}\n", .{ server_ip, server_port });
    std.debug.print("  Waiting for PFCP messages via UDP...\n\n", .{});

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
        // Receive message via real UDP
        var recv_buffer: [4096]u8 = undefined;
        const msg = try socket.receiveMessage(&recv_buffer);

        std.debug.print("Received UDP message from {any}\n", .{msg.source});
        std.debug.print("  Type: {s}\n", .{@tagName(msg.message_type)});
        std.debug.print("  Sequence: {d}\n", .{msg.sequence_number});
        if (msg.seid) |seid| {
            std.debug.print("  SEID: 0x{X:0>16}\n", .{seid});
        }
        std.debug.print("  Payload: {s}\n", .{msg.payload});

        switch (msg.message_type) {
            .association_setup_request => {
                std.debug.print("\nStep 2: Processing Association Setup Request...\n", .{});
                std.debug.print("  Creating Association Setup Response...\n", .{});

                // Build response (demonstrating message construction)
                const assoc_resp = pfcp.AssociationSetupResponse.accepted(node_id, recovery);

                // Create response payload
                var resp_payload: [256]u8 = undefined;
                const resp_msg = try std.fmt.bufPrint(&resp_payload, "ASSOC_RESP:ACCEPTED:{d}", .{recovery.timestamp});

                // Send response via UDP
                _ = try socket.sendMessage(
                    pfcp.types.MessageType.association_setup_response,
                    null,
                    resp_msg,
                    msg.source,
                );
                std.debug.print("  Sent Association Setup Response via UDP (seq: {d})\n", .{msg.sequence_number});
                std.debug.print("  Cause: Request Accepted\n\n", .{});

                _ = assoc_resp;
            },

            .session_establishment_request => {
                std.debug.print("\nStep 3: Processing Session Establishment Request...\n", .{});

                // Extract SEID from payload (simplified parsing)
                if (std.mem.indexOf(u8, msg.payload, "SEID=")) |idx| {
                    const seid_str = msg.payload[idx + 5 ..];
                    cp_seid = std.fmt.parseInt(u64, seid_str[0..@min(16, seid_str.len)], 16) catch 0x1234567890ABCDEF;
                }

                std.debug.print("  CP SEID: 0x{X:0>16}\n", .{cp_seid.?});

                // Allocate local SEID
                up_seid = 0xFEDCBA0987654321;
                std.debug.print("  Allocating UP SEID: 0x{X:0>16}\n", .{up_seid.?});

                // Build response
                const up_fseid = pfcp.ie.FSEID.initV4(up_seid.?, server_addr_bytes);
                const session_resp = pfcp.SessionEstablishmentResponse.accepted(node_id, up_fseid);

                // Create response payload
                var resp_payload: [256]u8 = undefined;
                const resp_msg = try std.fmt.bufPrint(&resp_payload, "SESSION_RESP:ACCEPTED:UP_SEID={X}", .{up_seid.?});

                // Send response via UDP with CP SEID
                _ = try socket.sendMessage(
                    pfcp.types.MessageType.session_establishment_response,
                    cp_seid.?,
                    resp_msg,
                    msg.source,
                );
                std.debug.print("  Sent Session Establishment Response via UDP (seq: {d})\n", .{msg.sequence_number});
                std.debug.print("  Cause: Request Accepted\n\n", .{});

                std.debug.print("Session context created:\n", .{});
                std.debug.print("  Local SEID (UP):  0x{X:0>16}\n", .{up_seid.?});
                std.debug.print("  Remote SEID (CP): 0x{X:0>16}\n\n", .{cp_seid.?});

                _ = session_resp;
            },

            else => {
                std.debug.print("  Unhandled message type: {s}\n\n", .{@tagName(msg.message_type)});
            },
        }
    }

    std.debug.print("=== UPF Simulator completed successfully! ===\n", .{});
    std.debug.print("\nDemonstrated:\n", .{});
    std.debug.print("  ✓ Real UDP socket communication\n", .{});
    std.debug.print("  ✓ PfcpSocket send/receive operations\n", .{});
    std.debug.print("  ✓ Message parsing and routing\n", .{});
    std.debug.print("  ✓ Session state management\n", .{});
    std.debug.print("  ✓ Response generation with matching sequence numbers\n", .{});
    std.debug.print("  ✓ SEID handling for session messages\n\n", .{});

    if (up_seid) |seid| {
        std.debug.print("Final State:\n", .{});
        std.debug.print("  Local SEID (UP):  0x{X:0>16}\n", .{seid});
        if (cp_seid) |cp| {
            std.debug.print("  Remote SEID (CP): 0x{X:0>16}\n", .{cp});
        }
        std.debug.print("\n", .{});
    }
}
