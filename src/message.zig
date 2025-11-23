// PFCP Messages module
// 3GPP TS 29.244 Section 7.4

const std = @import("std");
const types = @import("types.zig");
const ie = @import("ie.zig");

/// Heartbeat Request (3GPP TS 29.244 Section 7.4.4.1)
pub const HeartbeatRequest = struct {
    recovery_time_stamp: ie.RecoveryTimeStamp,

    pub fn init(recovery_time_stamp: ie.RecoveryTimeStamp) HeartbeatRequest {
        return .{ .recovery_time_stamp = recovery_time_stamp };
    }
};

/// Heartbeat Response (3GPP TS 29.244 Section 7.4.4.2)
pub const HeartbeatResponse = struct {
    recovery_time_stamp: ie.RecoveryTimeStamp,

    pub fn init(recovery_time_stamp: ie.RecoveryTimeStamp) HeartbeatResponse {
        return .{ .recovery_time_stamp = recovery_time_stamp };
    }
};

/// Association Setup Request (3GPP TS 29.244 Section 7.4.3.1)
pub const AssociationSetupRequest = struct {
    node_id: ie.NodeId,
    recovery_time_stamp: ie.RecoveryTimeStamp,
    up_function_features: ?u64 = null,
    cp_function_features: ?u64 = null,
    user_plane_ip_resource_information: ?[]const u8 = null,

    pub fn init(node_id: ie.NodeId, recovery_time_stamp: ie.RecoveryTimeStamp) AssociationSetupRequest {
        return .{
            .node_id = node_id,
            .recovery_time_stamp = recovery_time_stamp,
        };
    }
};

/// Association Setup Response (3GPP TS 29.244 Section 7.4.3.2)
pub const AssociationSetupResponse = struct {
    node_id: ie.NodeId,
    cause: ie.Cause,
    recovery_time_stamp: ie.RecoveryTimeStamp,
    up_function_features: ?u64 = null,
    cp_function_features: ?u64 = null,
    user_plane_ip_resource_information: ?[]const u8 = null,

    pub fn init(node_id: ie.NodeId, cause: ie.Cause, recovery_time_stamp: ie.RecoveryTimeStamp) AssociationSetupResponse {
        return .{
            .node_id = node_id,
            .cause = cause,
            .recovery_time_stamp = recovery_time_stamp,
        };
    }

    pub fn accepted(node_id: ie.NodeId, recovery_time_stamp: ie.RecoveryTimeStamp) AssociationSetupResponse {
        return .{
            .node_id = node_id,
            .cause = ie.Cause.accepted(),
            .recovery_time_stamp = recovery_time_stamp,
        };
    }
};

/// Session Establishment Request (3GPP TS 29.244 Section 7.5.2.1)
pub const SessionEstablishmentRequest = struct {
    node_id: ie.NodeId,
    f_seid: ie.FSEID,
    create_pdr: ?[]const ie.CreatePDR = null,
    create_far: ?[]const ie.CreateFAR = null,
    create_urr: ?[]const ie.CreateURR = null,
    create_qer: ?[]const ie.CreateQER = null,
    pdn_type: ?u8 = null,

    pub fn init(node_id: ie.NodeId, f_seid: ie.FSEID) SessionEstablishmentRequest {
        return .{
            .node_id = node_id,
            .f_seid = f_seid,
        };
    }

    pub fn withCreatePDR(self: SessionEstablishmentRequest, pdrs: []const ie.CreatePDR) SessionEstablishmentRequest {
        var result = self;
        result.create_pdr = pdrs;
        return result;
    }

    pub fn withCreateFAR(self: SessionEstablishmentRequest, fars: []const ie.CreateFAR) SessionEstablishmentRequest {
        var result = self;
        result.create_far = fars;
        return result;
    }

    pub fn withCreateURR(self: SessionEstablishmentRequest, urrs: []const ie.CreateURR) SessionEstablishmentRequest {
        var result = self;
        result.create_urr = urrs;
        return result;
    }

    pub fn withCreateQER(self: SessionEstablishmentRequest, qers: []const ie.CreateQER) SessionEstablishmentRequest {
        var result = self;
        result.create_qer = qers;
        return result;
    }
};

/// Created PDR IE (3GPP TS 29.244 Section 7.5.2.2)
/// Contains the PDR ID and optionally allocated F-TEID
pub const CreatedPDR = struct {
    pdr_id: ie.PDRID,
    f_teid: ?ie.FTEID = null,
    ue_ip_address: ?ie.UEIPAddress = null,

    pub fn init(pdr_id: ie.PDRID) CreatedPDR {
        return .{ .pdr_id = pdr_id };
    }

    pub fn withFTeid(self: CreatedPDR, f_teid: ie.FTEID) CreatedPDR {
        var result = self;
        result.f_teid = f_teid;
        return result;
    }

    pub fn withUeIp(self: CreatedPDR, ue_ip: ie.UEIPAddress) CreatedPDR {
        var result = self;
        result.ue_ip_address = ue_ip;
        return result;
    }
};

/// Session Establishment Response (3GPP TS 29.244 Section 7.5.2.2)
pub const SessionEstablishmentResponse = struct {
    node_id: ie.NodeId,
    cause: ie.Cause,
    f_seid: ?ie.FSEID = null,
    created_pdr: ?[]const CreatedPDR = null,
    load_control_information: ?[]const u8 = null,
    overload_control_information: ?[]const u8 = null,

    pub fn init(node_id: ie.NodeId, cause: ie.Cause) SessionEstablishmentResponse {
        return .{
            .node_id = node_id,
            .cause = cause,
        };
    }

    pub fn accepted(node_id: ie.NodeId, f_seid: ie.FSEID) SessionEstablishmentResponse {
        return .{
            .node_id = node_id,
            .cause = ie.Cause.accepted(),
            .f_seid = f_seid,
        };
    }

    pub fn withCreatedPDR(self: SessionEstablishmentResponse, pdrs: []const CreatedPDR) SessionEstablishmentResponse {
        var result = self;
        result.created_pdr = pdrs;
        return result;
    }
};

/// Session Modification Request (3GPP TS 29.244 Section 7.5.4.1)
pub const SessionModificationRequest = struct {
    f_seid: ?ie.FSEID = null,
    // Remove operations (will be implemented in Issue #4)
    remove_pdr: ?[]const ie.PDRID = null,
    remove_far: ?[]const ie.FARID = null,
    remove_urr: ?[]const ie.URRID = null,
    remove_qer: ?[]const ie.QERID = null,
    // Create operations
    create_pdr: ?[]const ie.CreatePDR = null,
    create_far: ?[]const ie.CreateFAR = null,
    create_urr: ?[]const ie.CreateURR = null,
    create_qer: ?[]const ie.CreateQER = null,
    // Update operations (will be implemented in Issue #4)
    update_pdr: ?[]const u8 = null,
    update_far: ?[]const u8 = null,
    update_urr: ?[]const u8 = null,
    update_qer: ?[]const u8 = null,

    pub fn init() SessionModificationRequest {
        return .{};
    }

    pub fn withFSEID(self: SessionModificationRequest, f_seid: ie.FSEID) SessionModificationRequest {
        var result = self;
        result.f_seid = f_seid;
        return result;
    }

    pub fn withCreatePDR(self: SessionModificationRequest, pdrs: []const ie.CreatePDR) SessionModificationRequest {
        var result = self;
        result.create_pdr = pdrs;
        return result;
    }

    pub fn withCreateFAR(self: SessionModificationRequest, fars: []const ie.CreateFAR) SessionModificationRequest {
        var result = self;
        result.create_far = fars;
        return result;
    }

    pub fn withCreateURR(self: SessionModificationRequest, urrs: []const ie.CreateURR) SessionModificationRequest {
        var result = self;
        result.create_urr = urrs;
        return result;
    }

    pub fn withCreateQER(self: SessionModificationRequest, qers: []const ie.CreateQER) SessionModificationRequest {
        var result = self;
        result.create_qer = qers;
        return result;
    }

    pub fn withRemovePDR(self: SessionModificationRequest, pdr_ids: []const ie.PDRID) SessionModificationRequest {
        var result = self;
        result.remove_pdr = pdr_ids;
        return result;
    }

    pub fn withRemoveFAR(self: SessionModificationRequest, far_ids: []const ie.FARID) SessionModificationRequest {
        var result = self;
        result.remove_far = far_ids;
        return result;
    }
};

/// Session Modification Response (3GPP TS 29.244 Section 7.5.4.2)
pub const SessionModificationResponse = struct {
    cause: ie.Cause,
    created_pdr: ?[]const CreatedPDR = null,
    load_control_information: ?[]const u8 = null,
    overload_control_information: ?[]const u8 = null,
    usage_report: ?[]const ie.UsageReportSMR = null,

    pub fn init(cause: ie.Cause) SessionModificationResponse {
        return .{ .cause = cause };
    }

    pub fn accepted() SessionModificationResponse {
        return .{ .cause = ie.Cause.accepted() };
    }

    pub fn withCreatedPDR(self: SessionModificationResponse, pdrs: []const CreatedPDR) SessionModificationResponse {
        var result = self;
        result.created_pdr = pdrs;
        return result;
    }

    pub fn withUsageReport(self: SessionModificationResponse, reports: []const ie.UsageReportSMR) SessionModificationResponse {
        var result = self;
        result.usage_report = reports;
        return result;
    }
};

/// Session Deletion Request (3GPP TS 29.244 Section 7.5.5.1)
pub const SessionDeletionRequest = struct {
    pub fn init() SessionDeletionRequest {
        return .{};
    }
};

/// Session Deletion Response (3GPP TS 29.244 Section 7.5.5.2)
pub const SessionDeletionResponse = struct {
    cause: ie.Cause,
    load_control_information: ?[]const u8 = null,
    overload_control_information: ?[]const u8 = null,
    usage_report: ?[]const ie.UsageReportSDR = null,

    pub fn init(cause: ie.Cause) SessionDeletionResponse {
        return .{ .cause = cause };
    }

    pub fn accepted() SessionDeletionResponse {
        return .{ .cause = ie.Cause.accepted() };
    }

    pub fn withUsageReport(self: SessionDeletionResponse, reports: []const ie.UsageReportSDR) SessionDeletionResponse {
        var result = self;
        result.usage_report = reports;
        return result;
    }
};

/// Session Report Request (3GPP TS 29.244 Section 7.5.8.1)
/// Sent from UPF to SMF to report usage, events, or errors
pub const SessionReportRequest = struct {
    report_type: ie.ReportType,
    usage_report: ?[]const ie.UsageReportSRR = null,
    downlink_data_report: ?ie.DownlinkDataReport = null,
    error_indication_report: ?ie.ErrorIndicationReport = null,
    load_control_information: ?[]const u8 = null,
    overload_control_information: ?[]const u8 = null,

    pub fn init(report_type: ie.ReportType) SessionReportRequest {
        return .{ .report_type = report_type };
    }

    pub fn usageReport(reports: []const ie.UsageReportSRR) SessionReportRequest {
        return .{
            .report_type = ie.ReportType.usageReport(),
            .usage_report = reports,
        };
    }

    pub fn downlinkData(report: ie.DownlinkDataReport) SessionReportRequest {
        return .{
            .report_type = ie.ReportType.downlinkDataReport(),
            .downlink_data_report = report,
        };
    }

    pub fn errorIndication(report: ie.ErrorIndicationReport) SessionReportRequest {
        return .{
            .report_type = ie.ReportType.errorIndicationReport(),
            .error_indication_report = report,
        };
    }

    pub fn withUsageReport(self: SessionReportRequest, reports: []const ie.UsageReportSRR) SessionReportRequest {
        var result = self;
        result.usage_report = reports;
        return result;
    }

    pub fn withDownlinkDataReport(self: SessionReportRequest, report: ie.DownlinkDataReport) SessionReportRequest {
        var result = self;
        result.downlink_data_report = report;
        return result;
    }
};

/// Session Report Response (3GPP TS 29.244 Section 7.5.8.2)
/// Sent from SMF to UPF acknowledging Session Report Request
pub const SessionReportResponse = struct {
    cause: ie.Cause,
    offending_ie: ?u16 = null,
    load_control_information: ?[]const u8 = null,
    overload_control_information: ?[]const u8 = null,

    pub fn init(cause: ie.Cause) SessionReportResponse {
        return .{ .cause = cause };
    }

    pub fn accepted() SessionReportResponse {
        return .{ .cause = ie.Cause.accepted() };
    }

    pub fn rejected(cause: types.CauseValue) SessionReportResponse {
        return .{ .cause = ie.Cause.init(cause) };
    }

    pub fn withOffendingIE(self: SessionReportResponse, ie_type: u16) SessionReportResponse {
        var result = self;
        result.offending_ie = ie_type;
        return result;
    }
};

test "Heartbeat message creation" {
    const recovery = ie.RecoveryTimeStamp.init(12345);
    const request = HeartbeatRequest.init(recovery);
    try std.testing.expectEqual(@as(u32, 12345), request.recovery_time_stamp.timestamp);

    const response = HeartbeatResponse.init(recovery);
    try std.testing.expectEqual(@as(u32, 12345), response.recovery_time_stamp.timestamp);
}

test "Association setup response helper" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const recovery = ie.RecoveryTimeStamp.init(12345);

    const response = AssociationSetupResponse.accepted(node_id, recovery);
    try std.testing.expect(response.cause.cause.isAccepted());
}

test "Session establishment response helper" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const fseid = ie.FSEID.initV4(12345, [_]u8{ 10, 0, 0, 1 });

    const response = SessionEstablishmentResponse.accepted(node_id, fseid);
    try std.testing.expect(response.cause.cause.isAccepted());
    try std.testing.expect(response.f_seid != null);
}

test "Session establishment request with PDRs and FARs" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const fseid = ie.FSEID.initV4(12345, [_]u8{ 10, 0, 0, 1 });

    // Create PDRs
    const pdr1 = ie.CreatePDR.init(
        ie.PDRID.init(1),
        ie.Precedence.init(100),
        ie.PDI.init(ie.SourceInterface.init(.access)),
    ).withFarId(ie.FARID.init(1));

    const pdr2 = ie.CreatePDR.init(
        ie.PDRID.init(2),
        ie.Precedence.init(200),
        ie.PDI.init(ie.SourceInterface.init(.core)),
    ).withFarId(ie.FARID.init(2));

    const pdrs = [_]ie.CreatePDR{ pdr1, pdr2 };

    // Create FARs
    const far1 = ie.CreateFAR.forward(ie.FARID.init(1), ie.DestinationInterface.init(.core));
    const far2 = ie.CreateFAR.drop(ie.FARID.init(2));

    const fars = [_]ie.CreateFAR{ far1, far2 };

    const request = SessionEstablishmentRequest.init(node_id, fseid)
        .withCreatePDR(&pdrs)
        .withCreateFAR(&fars);

    try std.testing.expect(request.create_pdr != null);
    try std.testing.expectEqual(@as(usize, 2), request.create_pdr.?.len);
    try std.testing.expectEqual(@as(u16, 1), request.create_pdr.?[0].pdr_id.rule_id);
    try std.testing.expectEqual(@as(u16, 2), request.create_pdr.?[1].pdr_id.rule_id);

    try std.testing.expect(request.create_far != null);
    try std.testing.expectEqual(@as(usize, 2), request.create_far.?.len);
    try std.testing.expect(request.create_far.?[0].apply_action.actions.forw);
    try std.testing.expect(request.create_far.?[1].apply_action.actions.drop);
}

test "Session establishment request with QERs and URRs" {
    const node_id = ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const fseid = ie.FSEID.initV4(12345, [_]u8{ 10, 0, 0, 1 });

    // Create QERs with rate limits
    const qer = ie.CreateQER.withRates(
        ie.QERID.init(1),
        100_000_000,
        200_000_000,
        50_000_000,
        100_000_000,
    );

    const qers = [_]ie.CreateQER{qer};

    // Create URR for volume measurement
    const urr = ie.CreateURR.init(
        ie.URRID.init(1),
        ie.MeasurementMethod.volume(),
    ).withVolumeThreshold(ie.VolumeThreshold.initTotal(1_000_000_000));

    const urrs = [_]ie.CreateURR{urr};

    const request = SessionEstablishmentRequest.init(node_id, fseid)
        .withCreateQER(&qers)
        .withCreateURR(&urrs);

    try std.testing.expect(request.create_qer != null);
    try std.testing.expectEqual(@as(usize, 1), request.create_qer.?.len);
    try std.testing.expect(request.create_qer.?[0].gate_status != null);

    try std.testing.expect(request.create_urr != null);
    try std.testing.expectEqual(@as(usize, 1), request.create_urr.?.len);
    try std.testing.expect(request.create_urr.?[0].measurement_method.flags.volum);
}

test "Created PDR with F-TEID" {
    const pdr_id = ie.PDRID.init(1);
    const f_teid = ie.FTEID.initV4(0x12345678, [_]u8{ 10, 0, 0, 1 });

    const created_pdr = CreatedPDR.init(pdr_id).withFTeid(f_teid);

    try std.testing.expectEqual(@as(u16, 1), created_pdr.pdr_id.rule_id);
    try std.testing.expect(created_pdr.f_teid != null);
    try std.testing.expectEqual(@as(u32, 0x12345678), created_pdr.f_teid.?.teid);
}

test "Session modification request" {
    const pdr = ie.CreatePDR.init(
        ie.PDRID.init(3),
        ie.Precedence.init(300),
        ie.PDI.init(ie.SourceInterface.init(.access)),
    );

    const pdrs = [_]ie.CreatePDR{pdr};
    const remove_pdrs = [_]ie.PDRID{ie.PDRID.init(1)};

    const request = SessionModificationRequest.init()
        .withCreatePDR(&pdrs)
        .withRemovePDR(&remove_pdrs);

    try std.testing.expect(request.create_pdr != null);
    try std.testing.expectEqual(@as(usize, 1), request.create_pdr.?.len);
    try std.testing.expect(request.remove_pdr != null);
    try std.testing.expectEqual(@as(usize, 1), request.remove_pdr.?.len);
    try std.testing.expectEqual(@as(u16, 1), request.remove_pdr.?[0].rule_id);
}

// ============================================================================
// Phase 6 Tests: Session Report Request/Response
// ============================================================================

test "Session Report Request with usage report" {
    const urr_id = ie.URRID.init(1);
    const ur_seqn = ie.URSeqn.init(100);
    const trigger = ie.UsageReportTrigger.periodic();
    const vm = ie.VolumeMeasurement.initTotal(1_000_000_000);

    const usage_report = ie.UsageReportSRR.init(urr_id, ur_seqn, trigger)
        .withVolumeMeasurement(vm);

    const reports = [_]ie.UsageReportSRR{usage_report};
    const request = SessionReportRequest.usageReport(&reports);

    try std.testing.expect(request.report_type.flags.usar);
    try std.testing.expect(request.usage_report != null);
    try std.testing.expectEqual(@as(usize, 1), request.usage_report.?.len);
}

test "Session Report Request with downlink data report" {
    const pdr_id = ie.PDRID.init(5);
    const dl_report = ie.DownlinkDataReport.init().withPdrId(pdr_id);

    const request = SessionReportRequest.downlinkData(dl_report);

    try std.testing.expect(request.report_type.flags.dldr);
    try std.testing.expect(request.downlink_data_report != null);
    try std.testing.expectEqual(@as(u16, 5), request.downlink_data_report.?.pdr_id.?.rule_id);
}

test "Session Report Response accepted" {
    const response = SessionReportResponse.accepted();
    try std.testing.expect(response.cause.cause.isAccepted());
}

test "Session Report Response rejected" {
    const response = SessionReportResponse.rejected(.session_context_not_found);
    try std.testing.expect(!response.cause.cause.isAccepted());
    try std.testing.expectEqual(types.CauseValue.session_context_not_found, response.cause.cause);
}

test "Session Deletion Response with usage report" {
    const urr_id = ie.URRID.init(1);
    const ur_seqn = ie.URSeqn.init(50);
    const trigger = ie.UsageReportTrigger.terminationReport();
    const vm = ie.VolumeMeasurement.initAll(5_000_000_000, 2_000_000_000, 3_000_000_000);

    const usage_report = ie.UsageReportSDR.init(urr_id, ur_seqn, trigger)
        .withVolumeMeasurement(vm);

    const reports = [_]ie.UsageReportSDR{usage_report};
    const response = SessionDeletionResponse.accepted().withUsageReport(&reports);

    try std.testing.expect(response.cause.cause.isAccepted());
    try std.testing.expect(response.usage_report != null);
    try std.testing.expectEqual(@as(usize, 1), response.usage_report.?.len);
}

test "Session Modification Response with usage report" {
    const urr_id = ie.URRID.init(3);
    const ur_seqn = ie.URSeqn.init(25);
    const trigger = ie.UsageReportTrigger.immediateReport();
    const dm = ie.DurationMeasurement.init(1800);

    const usage_report = ie.UsageReportSMR.init(urr_id, ur_seqn, trigger)
        .withDurationMeasurement(dm);

    const reports = [_]ie.UsageReportSMR{usage_report};
    const response = SessionModificationResponse.accepted().withUsageReport(&reports);

    try std.testing.expect(response.cause.cause.isAccepted());
    try std.testing.expect(response.usage_report != null);
    try std.testing.expectEqual(@as(usize, 1), response.usage_report.?.len);
}
