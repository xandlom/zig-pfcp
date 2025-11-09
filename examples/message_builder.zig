// Example: Building PFCP messages
//
// This example demonstrates how to construct various PFCP messages
// using the zig-pfcp library.

const std = @import("std");
const pfcp = @import("zig-pfcp");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("PFCP Message Builder Example\n", .{});
    try stdout.print("============================\n\n", .{});

    // Create a Heartbeat Request
    try stdout.print("1. Heartbeat Request\n", .{});
    const recovery = pfcp.ie.RecoveryTimeStamp.fromUnixTime(std.time.timestamp());
    const heartbeat_req = pfcp.HeartbeatRequest.init(recovery);
    try stdout.print("   Recovery timestamp: {d}\n\n", .{heartbeat_req.recovery_time_stamp.timestamp});

    // Create an Association Setup Request
    try stdout.print("2. Association Setup Request\n", .{});
    const node_id = pfcp.ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const assoc_req = pfcp.AssociationSetupRequest.init(node_id, recovery);
    try stdout.print("   Node ID: IPv4\n\n", .{});

    // Create an Association Setup Response (accepted)
    try stdout.print("3. Association Setup Response (Accepted)\n", .{});
    const assoc_resp = pfcp.AssociationSetupResponse.accepted(node_id, recovery);
    try stdout.print("   Cause: {s}\n\n", .{if (assoc_resp.cause.cause.isAccepted()) "Accepted" else "Rejected"});

    // Create a Session Establishment Request
    try stdout.print("4. Session Establishment Request\n", .{});
    const seid: u64 = 0x1234567890ABCDEF;
    const cp_fseid = pfcp.ie.FSEID.initV4(seid, [_]u8{ 10, 0, 0, 1 });
    const session_req = pfcp.SessionEstablishmentRequest.init(node_id, cp_fseid);
    try stdout.print("   CP F-SEID: {X:0>16}\n", .{session_req.f_seid.seid});
    try stdout.print("   CP IP: {d}.{d}.{d}.{d}\n\n", .{
        session_req.f_seid.ipv4.?[0],
        session_req.f_seid.ipv4.?[1],
        session_req.f_seid.ipv4.?[2],
        session_req.f_seid.ipv4.?[3],
    });

    // Create a Session Establishment Response (accepted)
    try stdout.print("5. Session Establishment Response (Accepted)\n", .{});
    const up_seid: u64 = 0xFEDCBA0987654321;
    const up_fseid = pfcp.ie.FSEID.initV4(up_seid, [_]u8{ 10, 0, 0, 2 });
    const session_resp = pfcp.SessionEstablishmentResponse.accepted(node_id, up_fseid);
    try stdout.print("   Cause: {s}\n", .{if (session_resp.cause.cause.isAccepted()) "Accepted" else "Rejected"});
    try stdout.print("   UP F-SEID: {X:0>16}\n", .{session_resp.f_seid.?.seid});
    try stdout.print("   UP IP: {d}.{d}.{d}.{d}\n\n", .{
        session_resp.f_seid.?.ipv4.?[0],
        session_resp.f_seid.?.ipv4.?[1],
        session_resp.f_seid.?.ipv4.?[2],
        session_resp.f_seid.?.ipv4.?[3],
    });

    // Demonstrate F-TEID with CHOOSE flag
    try stdout.print("6. F-TEID with CHOOSE flag\n", .{});
    const fteid_choose = pfcp.ie.FTEID.initChoose();
    try stdout.print("   CHOOSE flag: {s}\n\n", .{if (fteid_choose.flags.ch) "Set" else "Not set"});

    // Demonstrate UE IP Address
    try stdout.print("7. UE IP Address\n", .{});
    const ue_ip = pfcp.ie.UEIPAddress.initIpv4([_]u8{ 100, 64, 0, 1 }, true);
    try stdout.print("   IP: {d}.{d}.{d}.{d}\n", .{
        ue_ip.ipv4.?[0],
        ue_ip.ipv4.?[1],
        ue_ip.ipv4.?[2],
        ue_ip.ipv4.?[3],
    });
    try stdout.print("   Is Source: {s}\n\n", .{if (ue_ip.flags.sd) "Yes" else "No"});

    try stdout.print("Example completed successfully!\n", .{});
}
