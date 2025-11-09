// Information Elements (IE) module
// 3GPP TS 29.244 Section 8.2

const std = @import("std");
const types = @import("types.zig");

/// Generic IE Header
pub const IEHeader = packed struct {
    ie_type: u16,
    length: u16,

    pub fn init(ie_type: types.IEType, length: u16) IEHeader {
        return .{
            .ie_type = @intFromEnum(ie_type),
            .length = length,
        };
    }
};

/// Recovery Time Stamp IE (3GPP TS 29.244 Section 8.2.5)
pub const RecoveryTimeStamp = struct {
    /// Seconds since 1900-01-01 00:00:00 UTC
    timestamp: u32,

    pub fn init(timestamp: u32) RecoveryTimeStamp {
        return .{ .timestamp = timestamp };
    }

    pub fn fromUnixTime(unix_time: i64) RecoveryTimeStamp {
        // NTP epoch is 1900-01-01, Unix epoch is 1970-01-01
        // Difference is 2208988800 seconds
        const ntp_offset: i64 = 2208988800;
        return .{ .timestamp = @intCast(unix_time + ntp_offset) };
    }
};

/// Node ID IE (3GPP TS 29.244 Section 8.2.38)
pub const NodeId = struct {
    node_id_type: types.NodeIdType,
    value: union(enum) {
        ipv4: [4]u8,
        ipv6: [16]u8,
        fqdn: []const u8,
    },

    pub fn initIpv4(addr: [4]u8) NodeId {
        return .{
            .node_id_type = .ipv4,
            .value = .{ .ipv4 = addr },
        };
    }

    pub fn initIpv6(addr: [16]u8) NodeId {
        return .{
            .node_id_type = .ipv6,
            .value = .{ .ipv6 = addr },
        };
    }

    pub fn initFqdn(fqdn: []const u8) NodeId {
        return .{
            .node_id_type = .fqdn,
            .value = .{ .fqdn = fqdn },
        };
    }
};

/// F-SEID IE (3GPP TS 29.244 Section 8.2.37)
pub const FSEID = struct {
    flags: packed struct {
        v4: bool = false,
        v6: bool = false,
        _spare: u6 = 0,
    },
    seid: u64,
    ipv4: ?[4]u8 = null,
    ipv6: ?[16]u8 = null,

    pub fn initV4(seid: u64, ipv4: [4]u8) FSEID {
        return .{
            .flags = .{ .v4 = true },
            .seid = seid,
            .ipv4 = ipv4,
        };
    }

    pub fn initV6(seid: u64, ipv6: [16]u8) FSEID {
        return .{
            .flags = .{ .v6 = true },
            .seid = seid,
            .ipv6 = ipv6,
        };
    }

    pub fn initDual(seid: u64, ipv4: [4]u8, ipv6: [16]u8) FSEID {
        return .{
            .flags = .{ .v4 = true, .v6 = true },
            .seid = seid,
            .ipv4 = ipv4,
            .ipv6 = ipv6,
        };
    }
};

/// F-TEID IE (3GPP TS 29.244 Section 8.2.3)
pub const FTEID = struct {
    flags: packed struct {
        v4: bool = false,
        v6: bool = false,
        ch: bool = false, // CHOOSE flag
        chid: bool = false, // CHOOSE ID
        _spare: u4 = 0,
    },
    teid: u32,
    ipv4: ?[4]u8 = null,
    ipv6: ?[16]u8 = null,
    choose_id: ?u8 = null,

    pub fn initV4(teid: u32, ipv4: [4]u8) FTEID {
        return .{
            .flags = .{ .v4 = true },
            .teid = teid,
            .ipv4 = ipv4,
        };
    }

    pub fn initV6(teid: u32, ipv6: [16]u8) FTEID {
        return .{
            .flags = .{ .v6 = true },
            .teid = teid,
            .ipv6 = ipv6,
        };
    }

    pub fn initChoose() FTEID {
        return .{
            .flags = .{ .ch = true },
            .teid = 0,
        };
    }
};

/// UE IP Address IE (3GPP TS 29.244 Section 8.2.62)
pub const UEIPAddress = struct {
    flags: packed struct {
        v4: bool = false,
        v6: bool = false,
        sd: bool = false, // Source/Destination
        ipv6d: bool = false, // IPv6 Prefix Delegation
        chv4: bool = false, // CHOOSE IPv4
        chv6: bool = false, // CHOOSE IPv6
        _spare: u2 = 0,
    },
    ipv4: ?[4]u8 = null,
    ipv6: ?[16]u8 = null,
    ipv6_prefix_delegation: ?u8 = null,

    pub fn initIpv4(addr: [4]u8, is_source: bool) UEIPAddress {
        return .{
            .flags = .{ .v4 = true, .sd = is_source },
            .ipv4 = addr,
        };
    }

    pub fn initIpv6(addr: [16]u8, is_source: bool) UEIPAddress {
        return .{
            .flags = .{ .v6 = true, .sd = is_source },
            .ipv6 = addr,
        };
    }
};

/// PDR ID IE (3GPP TS 29.244 Section 8.2.36)
pub const PDRID = struct {
    rule_id: u16,

    pub fn init(rule_id: u16) PDRID {
        return .{ .rule_id = rule_id };
    }
};

/// FAR ID IE (3GPP TS 29.244 Section 8.2.74)
pub const FARID = struct {
    far_id: u32,

    pub fn init(far_id: u32) FARID {
        return .{ .far_id = far_id };
    }
};

/// URR ID IE (3GPP TS 29.244 Section 8.2.35)
pub const URRID = struct {
    urr_id: u32,

    pub fn init(urr_id: u32) URRID {
        return .{ .urr_id = urr_id };
    }
};

/// QER ID IE (3GPP TS 29.244 Section 8.2.123)
pub const QERID = struct {
    qer_id: u32,

    pub fn init(qer_id: u32) QERID {
        return .{ .qer_id = qer_id };
    }
};

/// Precedence IE (3GPP TS 29.244 Section 8.2.11)
pub const Precedence = struct {
    precedence: u32,

    pub fn init(precedence: u32) Precedence {
        return .{ .precedence = precedence };
    }
};

/// Cause IE (3GPP TS 29.244 Section 8.2.1)
pub const Cause = struct {
    cause: types.CauseValue,

    pub fn init(cause: types.CauseValue) Cause {
        return .{ .cause = cause };
    }

    pub fn accepted() Cause {
        return .{ .cause = .request_accepted };
    }

    pub fn rejected() Cause {
        return .{ .cause = .request_rejected };
    }
};

/// Source Interface IE (3GPP TS 29.244 Section 8.2.2)
pub const SourceInterface = struct {
    interface: types.SourceInterface,

    pub fn init(interface: types.SourceInterface) SourceInterface {
        return .{ .interface = interface };
    }
};

/// Destination Interface IE (3GPP TS 29.244 Section 8.2.42)
pub const DestinationInterface = struct {
    interface: types.DestinationInterface,

    pub fn init(interface: types.DestinationInterface) DestinationInterface {
        return .{ .interface = interface };
    }
};

/// Apply Action IE (3GPP TS 29.244 Section 8.2.25)
pub const ApplyAction = struct {
    actions: types.ApplyAction,

    pub fn init(actions: types.ApplyAction) ApplyAction {
        return .{ .actions = actions };
    }

    pub fn forward() ApplyAction {
        return .{ .actions = .{ .forw = true } };
    }

    pub fn drop() ApplyAction {
        return .{ .actions = .{ .drop = true } };
    }

    pub fn buffer() ApplyAction {
        return .{ .actions = .{ .buff = true } };
    }

    pub fn notifyCP() ApplyAction {
        return .{ .actions = .{ .forw = true, .nocp = false } };
    }
};

/// Network Instance IE (3GPP TS 29.244 Section 8.2.4)
pub const NetworkInstance = struct {
    name: []const u8,

    pub fn init(name: []const u8) NetworkInstance {
        return .{ .name = name };
    }
};

/// Outer Header Creation IE (3GPP TS 29.244 Section 8.2.56)
pub const OuterHeaderCreation = struct {
    flags: packed struct {
        gtpu_udp_ipv4: bool = false,
        gtpu_udp_ipv6: bool = false,
        udp_ipv4: bool = false,
        udp_ipv6: bool = false,
        ipv4: bool = false,
        ipv6: bool = false,
        ctag: bool = false,
        stag: bool = false,
    },
    teid: ?u32 = null,
    ipv4: ?[4]u8 = null,
    ipv6: ?[16]u8 = null,
    port: ?u16 = null,
    ctag: ?u16 = null,
    stag: ?u16 = null,

    pub fn initGtpuV4(teid: u32, ipv4: [4]u8) OuterHeaderCreation {
        return .{
            .flags = .{ .gtpu_udp_ipv4 = true },
            .teid = teid,
            .ipv4 = ipv4,
        };
    }

    pub fn initGtpuV6(teid: u32, ipv6: [16]u8) OuterHeaderCreation {
        return .{
            .flags = .{ .gtpu_udp_ipv6 = true },
            .teid = teid,
            .ipv6 = ipv6,
        };
    }
};

/// Outer Header Removal IE (3GPP TS 29.244 Section 8.2.95)
pub const OuterHeaderRemoval = struct {
    description: OuterHeaderRemovalDescription,

    pub const OuterHeaderRemovalDescription = enum(u8) {
        gtpu_udp_ipv4 = 0,
        gtpu_udp_ipv6 = 1,
        udp_ipv4 = 2,
        udp_ipv6 = 3,
        ipv4 = 4,
        ipv6 = 5,
        gtpu_udp_ip = 6,
        vlan_stag = 7,
        stag_and_ctag = 8,
        _,
    };

    pub fn init(description: OuterHeaderRemovalDescription) OuterHeaderRemoval {
        return .{ .description = description };
    }

    pub fn gtpuUdpIpv4() OuterHeaderRemoval {
        return .{ .description = .gtpu_udp_ipv4 };
    }
};

/// SDF Filter IE (3GPP TS 29.244 Section 8.2.5)
pub const SDFFilter = struct {
    flags: packed struct {
        fd: bool = false, // Flow Description present
        ttc: bool = false, // ToS Traffic Class present
        spi: bool = false, // Security Parameter Index present
        fl: bool = false, // Flow Label present
        bid: bool = false, // Bidirectional SDF Filter present
        _spare: u3 = 0,
    },
    flow_description: ?[]const u8 = null,
    tos_traffic_class: ?u16 = null,
    security_param_index: ?u32 = null,
    flow_label: ?u24 = null,

    pub fn initFlowDescription(desc: []const u8) SDFFilter {
        return .{
            .flags = .{ .fd = true },
            .flow_description = desc,
        };
    }
};

/// Gate Status IE (3GPP TS 29.244 Section 8.2.26)
pub const GateStatus = struct {
    ul_gate: GateValue,
    dl_gate: GateValue,

    pub const GateValue = enum(u2) {
        open = 0,
        closed = 1,
        _,
    };

    pub fn init(ul_gate: GateValue, dl_gate: GateValue) GateStatus {
        return .{ .ul_gate = ul_gate, .dl_gate = dl_gate };
    }

    pub fn open() GateStatus {
        return .{ .ul_gate = .open, .dl_gate = .open };
    }

    pub fn closed() GateStatus {
        return .{ .ul_gate = .closed, .dl_gate = .closed };
    }
};

/// MBR (Maximum Bitrate) IE (3GPP TS 29.244 Section 8.2.27)
pub const MBR = struct {
    ul_mbr: u64, // bits per second
    dl_mbr: u64, // bits per second

    pub fn init(ul_mbr: u64, dl_mbr: u64) MBR {
        return .{ .ul_mbr = ul_mbr, .dl_mbr = dl_mbr };
    }
};

/// GBR (Guaranteed Bitrate) IE (3GPP TS 29.244 Section 8.2.28)
pub const GBR = struct {
    ul_gbr: u64, // bits per second
    dl_gbr: u64, // bits per second

    pub fn init(ul_gbr: u64, dl_gbr: u64) GBR {
        return .{ .ul_gbr = ul_gbr, .dl_gbr = dl_gbr };
    }
};

/// Measurement Method IE (3GPP TS 29.244 Section 8.2.62)
pub const MeasurementMethod = struct {
    flags: packed struct {
        durat: bool = false, // Duration
        volum: bool = false, // Volume
        event: bool = false, // Event
        _spare: u5 = 0,
    },

    pub fn init(flags: packed struct { durat: bool = false, volum: bool = false, event: bool = false, _spare: u5 = 0 }) MeasurementMethod {
        return .{ .flags = flags };
    }

    pub fn volume() MeasurementMethod {
        return .{ .flags = .{ .volum = true } };
    }

    pub fn duration() MeasurementMethod {
        return .{ .flags = .{ .durat = true } };
    }
};

/// Reporting Triggers IE (3GPP TS 29.244 Section 8.2.37)
pub const ReportingTriggers = struct {
    flags: packed struct {
        perio: bool = false, // Periodic Reporting
        volth: bool = false, // Volume Threshold
        timth: bool = false, // Time Threshold
        quhti: bool = false, // Quota Holding Time
        start: bool = false, // Start of Traffic
        stopt: bool = false, // Stop of Traffic
        droth: bool = false, // Dropped DL Traffic Threshold
        liusa: bool = false, // Linked Usage Reporting
        volqu: bool = false, // Volume Quota
        timqu: bool = false, // Time Quota
        envcl: bool = false, // Envelope Closure
        monit: bool = false, // Monitoring Time
        termr: bool = false, // Termination Report
        _spare: u3 = 0,
    },

    pub fn init(flags: @TypeOf(ReportingTriggers{ .flags = undefined }).flags) ReportingTriggers {
        return .{ .flags = flags };
    }

    pub fn volumeThreshold() ReportingTriggers {
        return .{ .flags = .{ .volth = true } };
    }

    pub fn timeThreshold() ReportingTriggers {
        return .{ .flags = .{ .timth = true } };
    }

    pub fn periodic() ReportingTriggers {
        return .{ .flags = .{ .perio = true } };
    }
};

/// Volume Threshold IE (3GPP TS 29.244 Section 8.2.31)
pub const VolumeThreshold = struct {
    flags: packed struct {
        tovol: bool = false, // Total Volume
        ulvol: bool = false, // Uplink Volume
        dlvol: bool = false, // Downlink Volume
        _spare: u5 = 0,
    },
    total_volume: ?u64 = null,
    uplink_volume: ?u64 = null,
    downlink_volume: ?u64 = null,

    pub fn initTotal(total: u64) VolumeThreshold {
        return .{
            .flags = .{ .tovol = true },
            .total_volume = total,
        };
    }

    pub fn initUplinkDownlink(ul: u64, dl: u64) VolumeThreshold {
        return .{
            .flags = .{ .ulvol = true, .dlvol = true },
            .uplink_volume = ul,
            .downlink_volume = dl,
        };
    }
};

/// Time Threshold IE (3GPP TS 29.244 Section 8.2.32)
pub const TimeThreshold = struct {
    threshold: u32, // seconds

    pub fn init(threshold: u32) TimeThreshold {
        return .{ .threshold = threshold };
    }
};

// ============================================================================
// Grouped Information Elements
// ============================================================================

/// PDI (Packet Detection Information) IE (3GPP TS 29.244 Section 8.2.2)
/// This is a grouped IE containing packet detection criteria
pub const PDI = struct {
    source_interface: SourceInterface,
    f_teid: ?FTEID = null,
    network_instance: ?NetworkInstance = null,
    ue_ip_address: ?UEIPAddress = null,
    sdf_filter: ?SDFFilter = null,
    application_id: ?[]const u8 = null,

    pub fn init(source_interface: SourceInterface) PDI {
        return .{ .source_interface = source_interface };
    }

    pub fn withFTeid(self: PDI, f_teid: FTEID) PDI {
        var result = self;
        result.f_teid = f_teid;
        return result;
    }

    pub fn withUeIp(self: PDI, ue_ip: UEIPAddress) PDI {
        var result = self;
        result.ue_ip_address = ue_ip;
        return result;
    }

    pub fn withSdfFilter(self: PDI, sdf: SDFFilter) PDI {
        var result = self;
        result.sdf_filter = sdf;
        return result;
    }
};

/// Forwarding Parameters IE (3GPP TS 29.244 Section 8.2.4)
/// Grouped IE for forwarding configuration
pub const ForwardingParameters = struct {
    destination_interface: DestinationInterface,
    network_instance: ?NetworkInstance = null,
    outer_header_creation: ?OuterHeaderCreation = null,
    forwarding_policy: ?[]const u8 = null,

    pub fn init(destination_interface: DestinationInterface) ForwardingParameters {
        return .{ .destination_interface = destination_interface };
    }

    pub fn withOuterHeaderCreation(self: ForwardingParameters, ohc: OuterHeaderCreation) ForwardingParameters {
        var result = self;
        result.outer_header_creation = ohc;
        return result;
    }

    pub fn withNetworkInstance(self: ForwardingParameters, ni: NetworkInstance) ForwardingParameters {
        var result = self;
        result.network_instance = ni;
        return result;
    }
};

/// Create PDR (Packet Detection Rule) IE (3GPP TS 29.244 Section 8.2.1)
/// Main grouped IE for packet detection rules
pub const CreatePDR = struct {
    pdr_id: PDRID,
    precedence: Precedence,
    pdi: PDI,
    far_id: ?FARID = null,
    urr_ids: ?[]URRID = null,
    qer_ids: ?[]QERID = null,
    outer_header_removal: ?OuterHeaderRemoval = null,

    pub fn init(pdr_id: PDRID, precedence: Precedence, pdi: PDI) CreatePDR {
        return .{
            .pdr_id = pdr_id,
            .precedence = precedence,
            .pdi = pdi,
        };
    }

    pub fn withFarId(self: CreatePDR, far_id: FARID) CreatePDR {
        var result = self;
        result.far_id = far_id;
        return result;
    }

    pub fn withOuterHeaderRemoval(self: CreatePDR, ohr: OuterHeaderRemoval) CreatePDR {
        var result = self;
        result.outer_header_removal = ohr;
        return result;
    }
};

/// Create FAR (Forwarding Action Rule) IE (3GPP TS 29.244 Section 8.2.3)
/// Main grouped IE for forwarding action rules
pub const CreateFAR = struct {
    far_id: FARID,
    apply_action: ApplyAction,
    forwarding_parameters: ?ForwardingParameters = null,

    pub fn init(far_id: FARID, apply_action: ApplyAction) CreateFAR {
        return .{
            .far_id = far_id,
            .apply_action = apply_action,
        };
    }

    pub fn withForwardingParameters(self: CreateFAR, params: ForwardingParameters) CreateFAR {
        var result = self;
        result.forwarding_parameters = params;
        return result;
    }

    pub fn forward(far_id: FARID, destination: DestinationInterface) CreateFAR {
        return .{
            .far_id = far_id,
            .apply_action = ApplyAction.forward(),
            .forwarding_parameters = ForwardingParameters.init(destination),
        };
    }

    pub fn drop(far_id: FARID) CreateFAR {
        return .{
            .far_id = far_id,
            .apply_action = ApplyAction.drop(),
        };
    }
};

/// Create QER (QoS Enforcement Rule) IE (3GPP TS 29.244 Section 8.2.7)
/// Main grouped IE for QoS enforcement rules
pub const CreateQER = struct {
    qer_id: QERID,
    gate_status: ?GateStatus = null,
    mbr: ?MBR = null,
    gbr: ?GBR = null,
    qer_correlation_id: ?u32 = null,

    pub fn init(qer_id: QERID) CreateQER {
        return .{ .qer_id = qer_id };
    }

    pub fn withGateStatus(self: CreateQER, gate: GateStatus) CreateQER {
        var result = self;
        result.gate_status = gate;
        return result;
    }

    pub fn withMbr(self: CreateQER, mbr: MBR) CreateQER {
        var result = self;
        result.mbr = mbr;
        return result;
    }

    pub fn withGbr(self: CreateQER, gbr: GBR) CreateQER {
        var result = self;
        result.gbr = gbr;
        return result;
    }

    pub fn withRates(qer_id: QERID, ul_mbr: u64, dl_mbr: u64, ul_gbr: u64, dl_gbr: u64) CreateQER {
        return .{
            .qer_id = qer_id,
            .gate_status = GateStatus.open(),
            .mbr = MBR.init(ul_mbr, dl_mbr),
            .gbr = GBR.init(ul_gbr, dl_gbr),
        };
    }
};

/// Create URR (Usage Reporting Rule) IE (3GPP TS 29.244 Section 8.2.6)
/// Main grouped IE for usage reporting rules
pub const CreateURR = struct {
    urr_id: URRID,
    measurement_method: MeasurementMethod,
    reporting_triggers: ?ReportingTriggers = null,
    volume_threshold: ?VolumeThreshold = null,
    time_threshold: ?TimeThreshold = null,
    measurement_period: ?u32 = null,

    pub fn init(urr_id: URRID, measurement_method: MeasurementMethod) CreateURR {
        return .{
            .urr_id = urr_id,
            .measurement_method = measurement_method,
        };
    }

    pub fn withVolumeThreshold(self: CreateURR, threshold: VolumeThreshold) CreateURR {
        var result = self;
        result.volume_threshold = threshold;
        result.reporting_triggers = ReportingTriggers.volumeThreshold();
        return result;
    }

    pub fn withTimeThreshold(self: CreateURR, threshold: TimeThreshold) CreateURR {
        var result = self;
        result.time_threshold = threshold;
        result.reporting_triggers = ReportingTriggers.timeThreshold();
        return result;
    }

    pub fn withPeriodic(urr_id: URRID, period: u32) CreateURR {
        return .{
            .urr_id = urr_id,
            .measurement_method = MeasurementMethod.volume(),
            .measurement_period = period,
            .reporting_triggers = ReportingTriggers.periodic(),
        };
    }
};

test "Recovery timestamp conversion" {
    const unix_time: i64 = 1609459200; // 2021-01-01 00:00:00 UTC
    const recovery = RecoveryTimeStamp.fromUnixTime(unix_time);
    try std.testing.expect(recovery.timestamp > 0);
}

test "F-SEID initialization" {
    const fseid = FSEID.initV4(12345, [_]u8{ 192, 168, 1, 1 });
    try std.testing.expect(fseid.flags.v4);
    try std.testing.expect(!fseid.flags.v6);
    try std.testing.expectEqual(@as(u64, 12345), fseid.seid);
}

test "F-TEID CHOOSE flag" {
    const fteid = FTEID.initChoose();
    try std.testing.expect(fteid.flags.ch);
    try std.testing.expect(!fteid.flags.v4);
    try std.testing.expect(!fteid.flags.v6);
}

test "PDR creation with builder pattern" {
    const pdr_id = PDRID.init(1);
    const precedence = Precedence.init(100);
    const source_iface = SourceInterface.init(.access);
    const pdi = PDI.init(source_iface);
    const far_id = FARID.init(1);

    const pdr = CreatePDR.init(pdr_id, precedence, pdi).withFarId(far_id);

    try std.testing.expectEqual(@as(u16, 1), pdr.pdr_id.rule_id);
    try std.testing.expectEqual(@as(u32, 100), pdr.precedence.precedence);
    try std.testing.expect(pdr.far_id != null);
    try std.testing.expectEqual(@as(u32, 1), pdr.far_id.?.far_id);
}

test "FAR with forwarding parameters" {
    const far_id = FARID.init(1);
    const dest_iface = DestinationInterface.init(.core);
    const ohc = OuterHeaderCreation.initGtpuV4(0x12345678, [_]u8{ 10, 0, 0, 1 });

    const forwarding_params = ForwardingParameters.init(dest_iface)
        .withOuterHeaderCreation(ohc);

    const far = CreateFAR.init(far_id, ApplyAction.forward())
        .withForwardingParameters(forwarding_params);

    try std.testing.expectEqual(@as(u32, 1), far.far_id.far_id);
    try std.testing.expect(far.apply_action.actions.forw);
    try std.testing.expect(far.forwarding_parameters != null);
    try std.testing.expect(far.forwarding_parameters.?.outer_header_creation != null);
    try std.testing.expect(far.forwarding_parameters.?.outer_header_creation.?.flags.gtpu_udp_ipv4);
}

test "FAR convenience constructors" {
    const far_forward = CreateFAR.forward(FARID.init(1), DestinationInterface.init(.core));
    try std.testing.expect(far_forward.apply_action.actions.forw);
    try std.testing.expect(far_forward.forwarding_parameters != null);

    const far_drop = CreateFAR.drop(FARID.init(2));
    try std.testing.expect(far_drop.apply_action.actions.drop);
    try std.testing.expect(far_drop.forwarding_parameters == null);
}

test "QER with rate limiting" {
    const qer_id = QERID.init(1);
    const ul_mbr: u64 = 100_000_000; // 100 Mbps
    const dl_mbr: u64 = 200_000_000; // 200 Mbps
    const ul_gbr: u64 = 50_000_000; // 50 Mbps
    const dl_gbr: u64 = 100_000_000; // 100 Mbps

    const qer = CreateQER.withRates(qer_id, ul_mbr, dl_mbr, ul_gbr, dl_gbr);

    try std.testing.expectEqual(@as(u32, 1), qer.qer_id.qer_id);
    try std.testing.expect(qer.gate_status != null);
    try std.testing.expectEqual(GateStatus.GateValue.open, qer.gate_status.?.ul_gate);
    try std.testing.expectEqual(GateStatus.GateValue.open, qer.gate_status.?.dl_gate);
    try std.testing.expect(qer.mbr != null);
    try std.testing.expectEqual(ul_mbr, qer.mbr.?.ul_mbr);
    try std.testing.expectEqual(dl_mbr, qer.mbr.?.dl_mbr);
    try std.testing.expect(qer.gbr != null);
    try std.testing.expectEqual(ul_gbr, qer.gbr.?.ul_gbr);
    try std.testing.expectEqual(dl_gbr, qer.gbr.?.dl_gbr);
}

test "URR with volume threshold" {
    const urr_id = URRID.init(1);
    const measurement_method = MeasurementMethod.volume();
    const volume_threshold = VolumeThreshold.initTotal(1_000_000_000); // 1 GB

    const urr = CreateURR.init(urr_id, measurement_method)
        .withVolumeThreshold(volume_threshold);

    try std.testing.expectEqual(@as(u32, 1), urr.urr_id.urr_id);
    try std.testing.expect(urr.measurement_method.flags.volum);
    try std.testing.expect(urr.volume_threshold != null);
    try std.testing.expectEqual(@as(u64, 1_000_000_000), urr.volume_threshold.?.total_volume.?);
    try std.testing.expect(urr.reporting_triggers != null);
    try std.testing.expect(urr.reporting_triggers.?.flags.volth);
}

test "URR with time threshold" {
    const urr_id = URRID.init(2);
    const measurement_method = MeasurementMethod.duration();
    const time_threshold = TimeThreshold.init(3600); // 1 hour

    const urr = CreateURR.init(urr_id, measurement_method)
        .withTimeThreshold(time_threshold);

    try std.testing.expectEqual(@as(u32, 2), urr.urr_id.urr_id);
    try std.testing.expect(urr.measurement_method.flags.durat);
    try std.testing.expect(urr.time_threshold != null);
    try std.testing.expectEqual(@as(u32, 3600), urr.time_threshold.?.threshold);
    try std.testing.expect(urr.reporting_triggers != null);
    try std.testing.expect(urr.reporting_triggers.?.flags.timth);
}

test "URR periodic reporting" {
    const urr = CreateURR.withPeriodic(URRID.init(3), 60); // 60 seconds

    try std.testing.expectEqual(@as(u32, 3), urr.urr_id.urr_id);
    try std.testing.expect(urr.measurement_method.flags.volum);
    try std.testing.expectEqual(@as(u32, 60), urr.measurement_period.?);
    try std.testing.expect(urr.reporting_triggers != null);
    try std.testing.expect(urr.reporting_triggers.?.flags.perio);
}

test "Complete PDR with all components" {
    const pdr_id = PDRID.init(1);
    const precedence = Precedence.init(100);

    // Create PDI with all optional fields
    const source_iface = SourceInterface.init(.access);
    const f_teid = FTEID.initV4(0xAABBCCDD, [_]u8{ 192, 168, 1, 100 });
    const ue_ip = UEIPAddress.initIpv4([_]u8{ 10, 0, 0, 1 }, false);
    const sdf = SDFFilter.initFlowDescription("permit in ip from any to 8.8.8.8");

    const pdi = PDI.init(source_iface)
        .withFTeid(f_teid)
        .withUeIp(ue_ip)
        .withSdfFilter(sdf);

    const far_id = FARID.init(1);
    const ohr = OuterHeaderRemoval.gtpuUdpIpv4();

    const pdr = CreatePDR.init(pdr_id, precedence, pdi)
        .withFarId(far_id)
        .withOuterHeaderRemoval(ohr);

    try std.testing.expectEqual(@as(u16, 1), pdr.pdr_id.rule_id);
    try std.testing.expectEqual(@as(u32, 100), pdr.precedence.precedence);
    try std.testing.expect(pdr.pdi.f_teid != null);
    try std.testing.expect(pdr.pdi.ue_ip_address != null);
    try std.testing.expect(pdr.pdi.sdf_filter != null);
    try std.testing.expect(pdr.far_id != null);
    try std.testing.expect(pdr.outer_header_removal != null);
}

test "Gate status operations" {
    const open_gate = GateStatus.open();
    try std.testing.expectEqual(GateStatus.GateValue.open, open_gate.ul_gate);
    try std.testing.expectEqual(GateStatus.GateValue.open, open_gate.dl_gate);

    const closed_gate = GateStatus.closed();
    try std.testing.expectEqual(GateStatus.GateValue.closed, closed_gate.ul_gate);
    try std.testing.expectEqual(GateStatus.GateValue.closed, closed_gate.dl_gate);

    const mixed_gate = GateStatus.init(.open, .closed);
    try std.testing.expectEqual(GateStatus.GateValue.open, mixed_gate.ul_gate);
    try std.testing.expectEqual(GateStatus.GateValue.closed, mixed_gate.dl_gate);
}

test "Apply action flags" {
    const forward_action = ApplyAction.forward();
    try std.testing.expect(forward_action.actions.forw);
    try std.testing.expect(!forward_action.actions.drop);

    const drop_action = ApplyAction.drop();
    try std.testing.expect(drop_action.actions.drop);
    try std.testing.expect(!drop_action.actions.forw);

    const buffer_action = ApplyAction.buffer();
    try std.testing.expect(buffer_action.actions.buff);
}

test "Outer header creation for IPv4 and IPv6" {
    const ohc_v4 = OuterHeaderCreation.initGtpuV4(0x12345678, [_]u8{ 10, 0, 0, 1 });
    try std.testing.expect(ohc_v4.flags.gtpu_udp_ipv4);
    try std.testing.expect(!ohc_v4.flags.gtpu_udp_ipv6);
    try std.testing.expectEqual(@as(u32, 0x12345678), ohc_v4.teid.?);

    const ohc_v6 = OuterHeaderCreation.initGtpuV6(0x87654321, [_]u8{0x20} ++ [_]u8{0x01} ++ [_]u8{0x0d} ++ [_]u8{0xb8} ++ [_]u8{0} ** 12);
    try std.testing.expect(!ohc_v6.flags.gtpu_udp_ipv4);
    try std.testing.expect(ohc_v6.flags.gtpu_udp_ipv6);
    try std.testing.expectEqual(@as(u32, 0x87654321), ohc_v6.teid.?);
}
