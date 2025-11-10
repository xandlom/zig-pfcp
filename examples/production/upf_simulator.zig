// Production UPF (User Plane Function) Simulator
// Demonstrates a realistic UPF implementation using the PFCP library

const std = @import("std");
const pfcp = @import("zig-pfcp");

const UPF_PORT = 8806;
const SMF_ADDR = "127.0.0.1";
const SMF_PORT = 8805;

const Session = struct {
    seid: u64,
    smf_seid: u64,
    pdr_count: u32,
    far_count: u32,
    qer_count: u32,
    created_at: i64,

    pub fn init(seid: u64, smf_seid: u64) Session {
        return .{
            .seid = seid,
            .smf_seid = smf_seid,
            .pdr_count = 0,
            .far_count = 0,
            .qer_count = 0,
            .created_at = std.time.milliTimestamp(),
        };
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== PFCP UPF Simulator ===\n", .{});
    std.debug.print("Starting UPF on port {d}...\n\n", .{UPF_PORT});

    // Create PFCP socket
    const bind_addr = try std.net.Address.parseIp4("0.0.0.0", UPF_PORT);
    var socket = try pfcp.PfcpSocket.init(allocator, bind_addr);
    defer socket.deinit();

    std.debug.print("UPF ready. Listening on {any}:{}\n", .{ bind_addr, UPF_PORT });
    std.debug.print("Expecting SMF at {s}:{}\n\n", .{ SMF_ADDR, SMF_PORT });

    // Session management
    var sessions = std.AutoHashMap(u64, Session).init(allocator);
    defer sessions.deinit();

    // UPF state
    var association_established = false;
    const recovery_timestamp: u32 = @intCast(@divFloor(std.time.timestamp() + 2208988800, 1));

    std.debug.print("UPF Node ID: 127.0.0.1\n", .{});
    std.debug.print("Recovery Timestamp: {d}\n", .{recovery_timestamp});
    std.debug.print("UP Function Features: 0x0003 (example)\n\n", .{});

    // Simulate UPF operations
    std.debug.print("Waiting for PFCP messages from SMF...\n", .{});
    std.debug.print("(In a real implementation, this would receive and process messages)\n\n", .{});

    // Simulate receiving messages
    try simulateMessageHandling(&socket, &sessions, &association_established, recovery_timestamp, allocator);

    std.debug.print("\nUPF Simulator completed.\n", .{});
}

fn simulateMessageHandling(
    socket: *pfcp.PfcpSocket,
    sessions: *std.AutoHashMap(u64, Session),
    association_established: *bool,
    recovery_timestamp: u32,
    allocator: std.mem.Allocator,
) !void {
    _ = allocator;

    // Simulate receiving Association Setup Request
    std.debug.print("Step 1: Received Association Setup Request (simulated)\n", .{});
    try handleAssociationSetup(socket, association_established, recovery_timestamp);
    std.Thread.sleep(std.time.ns_per_s * 1);

    // Simulate receiving Heartbeat Request
    std.debug.print("\nStep 2: Received Heartbeat Request (simulated)\n", .{});
    try handleHeartbeat(socket, recovery_timestamp);
    std.Thread.sleep(std.time.ns_per_s * 1);

    // Simulate receiving Session Establishment Request
    std.debug.print("\nStep 3: Received Session Establishment Request (simulated)\n", .{});
    const session_seid: u64 = 0xFEDCBA0987654321;
    const smf_seid: u64 = 0x1234567890ABCDEF;
    try handleSessionEstablishment(socket, sessions, session_seid, smf_seid);
    std.Thread.sleep(std.time.ns_per_s * 1);

    // Simulate receiving Session Modification Request
    std.debug.print("\nStep 4: Received Session Modification Request (simulated)\n", .{});
    try handleSessionModification(socket, sessions, smf_seid);
    std.Thread.sleep(std.time.ns_per_s * 1);

    // Simulate receiving Session Deletion Request
    std.debug.print("\nStep 5: Received Session Deletion Request (simulated)\n", .{});
    try handleSessionDeletion(socket, sessions, smf_seid);
}

fn handleAssociationSetup(
    socket: *pfcp.PfcpSocket,
    association_established: *bool,
    recovery_timestamp: u32,
) !void {

    const node_id = pfcp.ie.NodeId.initIpv4([_]u8{ 127, 0, 0, 1 });
    const recovery = pfcp.ie.RecoveryTimeStamp.init(recovery_timestamp);

    const response = pfcp.AssociationSetupResponse.accepted(node_id, recovery);

    std.debug.print("  Processing Association Setup...\n", .{});
    std.debug.print("  Status: ACCEPTED\n", .{});
    std.debug.print("  Node ID: 127.0.0.1\n", .{});
    std.debug.print("  UP Features: 0x0003\n", .{});

    association_established.* = true;

    _ = socket;
    _ = response;
}

fn handleHeartbeat(socket: *pfcp.PfcpSocket, recovery_timestamp: u32) !void {

    const recovery = pfcp.ie.RecoveryTimeStamp.init(recovery_timestamp);
    const response = pfcp.HeartbeatResponse.init(recovery);

    std.debug.print("  Processing Heartbeat...\n", .{});
    std.debug.print("  Recovery Time: {d}\n", .{response.recovery_time_stamp.timestamp});

    _ = socket;
}

fn handleSessionEstablishment(
    socket: *pfcp.PfcpSocket,
    sessions: *std.AutoHashMap(u64, Session),
    upf_seid: u64,
    smf_seid: u64,
) !void {

    // Create session
    const session = Session.init(upf_seid, smf_seid);
    try sessions.put(smf_seid, session);

    const node_id = pfcp.ie.NodeId.initIpv4([_]u8{ 127, 0, 0, 1 });
    const fseid = pfcp.ie.FSEID.initV4(upf_seid, [_]u8{ 127, 0, 0, 1 });

    const response = pfcp.SessionEstablishmentResponse.accepted(node_id, fseid);

    std.debug.print("  Processing Session Establishment...\n", .{});
    std.debug.print("  Status: ACCEPTED\n", .{});
    std.debug.print("  SMF SEID: 0x{x:0>16}\n", .{smf_seid});
    std.debug.print("  UPF SEID: 0x{x:0>16}\n", .{upf_seid});
    std.debug.print("  Total Sessions: {d}\n", .{sessions.count()});

    _ = socket;
    _ = response;
}

fn handleSessionModification(
    socket: *pfcp.PfcpSocket,
    sessions: *std.AutoHashMap(u64, Session),
    seid: u64,
) !void {

    if (sessions.get(seid)) |session| {
        std.debug.print("  Processing Session Modification...\n", .{});
        std.debug.print("  Status: ACCEPTED\n", .{});
        std.debug.print("  SEID: 0x{x:0>16}\n", .{seid});
        std.debug.print("  PDRs: {d}, FARs: {d}, QERs: {d}\n", .{
            session.pdr_count,
            session.far_count,
            session.qer_count,
        });

        const response = pfcp.message.SessionModificationResponse.accepted();
        _ = response;
    } else {
        std.debug.print("  ERROR: Session not found (SEID: 0x{x:0>16})\n", .{seid});
    }

    _ = socket;
}

fn handleSessionDeletion(
    socket: *pfcp.PfcpSocket,
    sessions: *std.AutoHashMap(u64, Session),
    seid: u64,
) !void {

    if (sessions.remove(seid)) {
        std.debug.print("  Processing Session Deletion...\n", .{});
        std.debug.print("  Status: ACCEPTED\n", .{});
        std.debug.print("  SEID: 0x{x:0>16}\n", .{seid});
        std.debug.print("  Remaining Sessions: {d}\n", .{sessions.count()});

        const response = pfcp.message.SessionDeletionResponse.accepted();
        _ = response;
    } else {
        std.debug.print("  ERROR: Session not found (SEID: 0x{x:0>16})\n", .{seid});
    }

    _ = socket;
}
