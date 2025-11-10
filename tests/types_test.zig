// Comprehensive tests for types module
const std = @import("std");
const types = @import("../src/types.zig");

test "PFCP version constant" {
    try std.testing.expectEqual(@as(u8, 1), types.PFCP_VERSION);
}

test "PFCP port constant" {
    try std.testing.expectEqual(@as(u16, 8805), types.PFCP_PORT);
}

test "PfcpHeader - node message without SEID" {
    const header = types.PfcpHeader.init(.heartbeat_request, false);

    try std.testing.expectEqual(@as(u4, 0), header.spare);
    try std.testing.expectEqual(@as(u4, 1), header.version);
    try std.testing.expectEqual(@as(u2, 0), header.spare2);
    try std.testing.expectEqual(false, header.mp);
    try std.testing.expectEqual(false, header.s);
    try std.testing.expectEqual(@as(u8, 1), header.message_type);
    try std.testing.expectEqual(@as(usize, 8), header.getHeaderLength());
    try std.testing.expect(header.seid == null);
}

test "PfcpHeader - session message with SEID" {
    const header = types.PfcpHeader.init(.session_establishment_request, true);

    try std.testing.expectEqual(true, header.s);
    try std.testing.expectEqual(@as(u8, 50), header.message_type);
    try std.testing.expectEqual(@as(usize, 16), header.getHeaderLength());
    try std.testing.expect(header.seid != null);
}

test "MessageType - all node messages" {
    const node_messages = [_]types.MessageType{
        .heartbeat_request,
        .heartbeat_response,
        .pfd_management_request,
        .pfd_management_response,
        .association_setup_request,
        .association_setup_response,
        .association_update_request,
        .association_update_response,
        .association_release_request,
        .association_release_response,
        .version_not_supported_response,
        .node_report_request,
        .node_report_response,
        .session_set_deletion_request,
        .session_set_deletion_response,
    };

    for (node_messages) |msg_type| {
        try std.testing.expect(!msg_type.hasSession());
    }
}

test "MessageType - all session messages" {
    const session_messages = [_]types.MessageType{
        .session_establishment_request,
        .session_establishment_response,
        .session_modification_request,
        .session_modification_response,
        .session_deletion_request,
        .session_deletion_response,
        .session_report_request,
        .session_report_response,
    };

    for (session_messages) |msg_type| {
        try std.testing.expect(msg_type.hasSession());
    }
}

test "MessageType - enum values" {
    try std.testing.expectEqual(@as(u8, 1), @intFromEnum(types.MessageType.heartbeat_request));
    try std.testing.expectEqual(@as(u8, 5), @intFromEnum(types.MessageType.association_setup_request));
    try std.testing.expectEqual(@as(u8, 50), @intFromEnum(types.MessageType.session_establishment_request));
}

test "NodeIdType - enum values" {
    try std.testing.expectEqual(@as(u4, 0), @intFromEnum(types.NodeIdType.ipv4));
    try std.testing.expectEqual(@as(u4, 1), @intFromEnum(types.NodeIdType.ipv6));
    try std.testing.expectEqual(@as(u4, 2), @intFromEnum(types.NodeIdType.fqdn));
}

test "CauseValue - accepted values" {
    const accepted_values = [_]types.CauseValue{
        .request_accepted,
        .more_usage_report_to_send,
    };

    for (accepted_values) |cause| {
        try std.testing.expect(cause.isAccepted());
    }
}

test "CauseValue - rejected values" {
    const rejected_values = [_]types.CauseValue{
        .request_rejected,
        .session_context_not_found,
        .mandatory_ie_missing,
        .conditional_ie_missing,
        .invalid_length,
        .mandatory_ie_incorrect,
        .invalid_forwarding_policy,
        .invalid_f_teid_allocation_option,
        .no_established_pfcp_association,
        .rule_creation_modification_failure,
        .pfcp_entity_in_congestion,
        .no_resources_available,
        .service_not_supported,
        .system_failure,
        .redirection_requested,
        .all_dynamic_addresses_occupied,
    };

    for (rejected_values) |cause| {
        try std.testing.expect(!cause.isAccepted());
    }
}

test "SourceInterface - all values" {
    try std.testing.expectEqual(@as(u4, 0), @intFromEnum(types.SourceInterface.access));
    try std.testing.expectEqual(@as(u4, 1), @intFromEnum(types.SourceInterface.core));
    try std.testing.expectEqual(@as(u4, 2), @intFromEnum(types.SourceInterface.sgi_lan));
    try std.testing.expectEqual(@as(u4, 3), @intFromEnum(types.SourceInterface.cp_function));
}

test "DestinationInterface - all values" {
    try std.testing.expectEqual(@as(u4, 0), @intFromEnum(types.DestinationInterface.access));
    try std.testing.expectEqual(@as(u4, 1), @intFromEnum(types.DestinationInterface.core));
    try std.testing.expectEqual(@as(u4, 2), @intFromEnum(types.DestinationInterface.sgi_lan));
    try std.testing.expectEqual(@as(u4, 3), @intFromEnum(types.DestinationInterface.cp_function));
    try std.testing.expectEqual(@as(u4, 4), @intFromEnum(types.DestinationInterface.li_function));
}

test "ApplyAction - default initialization" {
    const action = types.ApplyAction{};

    try std.testing.expectEqual(false, action.drop);
    try std.testing.expectEqual(false, action.forw);
    try std.testing.expectEqual(false, action.buff);
    try std.testing.expectEqual(false, action.nocp);
    try std.testing.expectEqual(false, action.dupl);
}

test "ApplyAction - forward action" {
    const action = types.ApplyAction{ .forw = true };

    try std.testing.expectEqual(false, action.drop);
    try std.testing.expectEqual(true, action.forw);
}

test "ApplyAction - drop and notify action" {
    const action = types.ApplyAction{
        .drop = true,
        .nocp = true,
    };

    try std.testing.expectEqual(true, action.drop);
    try std.testing.expectEqual(true, action.nocp);
    try std.testing.expectEqual(false, action.forw);
}

test "PduSessionType - enum values" {
    try std.testing.expectEqual(@as(u4, 1), @intFromEnum(types.PduSessionType.ipv4));
    try std.testing.expectEqual(@as(u4, 2), @intFromEnum(types.PduSessionType.ipv6));
    try std.testing.expectEqual(@as(u4, 3), @intFromEnum(types.PduSessionType.ipv4v6));
    try std.testing.expectEqual(@as(u4, 4), @intFromEnum(types.PduSessionType.unstructured));
    try std.testing.expectEqual(@as(u4, 5), @intFromEnum(types.PduSessionType.ethernet));
}

test "RatType - 5G NR" {
    try std.testing.expectEqual(@as(u8, 10), @intFromEnum(types.RatType.nr));
}

test "RatType - LTE" {
    try std.testing.expectEqual(@as(u8, 6), @intFromEnum(types.RatType.eutran));
}

test "IEType - core IEs" {
    try std.testing.expectEqual(@as(u16, 19), @intFromEnum(types.IEType.cause));
    try std.testing.expectEqual(@as(u16, 21), @intFromEnum(types.IEType.f_teid));
    try std.testing.expectEqual(@as(u16, 57), @intFromEnum(types.IEType.f_seid));
    try std.testing.expectEqual(@as(u16, 60), @intFromEnum(types.IEType.node_id));
    try std.testing.expectEqual(@as(u16, 96), @intFromEnum(types.IEType.recovery_time_stamp));
}

test "IEType - rule IEs" {
    try std.testing.expectEqual(@as(u16, 1), @intFromEnum(types.IEType.create_pdr));
    try std.testing.expectEqual(@as(u16, 3), @intFromEnum(types.IEType.create_far));
    try std.testing.expectEqual(@as(u16, 6), @intFromEnum(types.IEType.create_urr));
    try std.testing.expectEqual(@as(u16, 7), @intFromEnum(types.IEType.create_qer));
}

test "IEType - 5G advanced IEs" {
    try std.testing.expectEqual(@as(u16, 124), @intFromEnum(types.IEType.pdu_session_type));
    try std.testing.expectEqual(@as(u16, 125), @intFromEnum(types.IEType.qfi));
    try std.testing.expectEqual(@as(u16, 228), @intFromEnum(types.IEType.s_nssai));
}
