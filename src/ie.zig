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

// ============================================================================
// Phase 5: Advanced 5G Features
// ============================================================================

/// S-NSSAI (Single Network Slice Selection Assistance Information) IE (3GPP TS 29.244 Section 8.2.136)
/// Used for network slicing in 5G
pub const SNSSAI = struct {
    sst: u8, // Slice/Service Type
    sd: ?u24 = null, // Slice Differentiator (optional)

    pub fn init(sst: u8) SNSSAI {
        return .{ .sst = sst };
    }

    pub fn initWithSd(sst: u8, sd: u24) SNSSAI {
        return .{ .sst = sst, .sd = sd };
    }

    /// eMBB (Enhanced Mobile Broadband) slice
    pub fn embb() SNSSAI {
        return .{ .sst = 1 };
    }

    /// URLLC (Ultra-Reliable Low Latency Communications) slice
    pub fn urllc() SNSSAI {
        return .{ .sst = 2 };
    }

    /// MIoT (Massive IoT) slice
    pub fn miot() SNSSAI {
        return .{ .sst = 3 };
    }
};

/// PDU Session Type IE (3GPP TS 29.244 Section 8.2.125)
pub const PduSessionType = struct {
    pdu_session_type: types.PduSessionType,

    pub fn init(pdu_session_type: types.PduSessionType) PduSessionType {
        return .{ .pdu_session_type = pdu_session_type };
    }

    pub fn ipv4() PduSessionType {
        return .{ .pdu_session_type = .ipv4 };
    }

    pub fn ipv6() PduSessionType {
        return .{ .pdu_session_type = .ipv6 };
    }

    pub fn ipv4v6() PduSessionType {
        return .{ .pdu_session_type = .ipv4v6 };
    }

    pub fn ethernet() PduSessionType {
        return .{ .pdu_session_type = .ethernet };
    }

    pub fn unstructured() PduSessionType {
        return .{ .pdu_session_type = .unstructured };
    }
};

/// QFI (QoS Flow Identifier) IE (3GPP TS 29.244 Section 8.2.89)
pub const QFI = struct {
    qfi: u6, // QoS Flow Identifier (6 bits)

    pub fn init(qfi: u6) QFI {
        return .{ .qfi = qfi };
    }
};

/// Volume Quota IE (3GPP TS 29.244 Section 8.2.73)
pub const VolumeQuota = struct {
    flags: packed struct {
        tovol: bool = false, // Total Volume
        ulvol: bool = false, // Uplink Volume
        dlvol: bool = false, // Downlink Volume
        _spare: u5 = 0,
    },
    total_volume: ?u64 = null,
    uplink_volume: ?u64 = null,
    downlink_volume: ?u64 = null,

    pub fn initTotal(total: u64) VolumeQuota {
        return .{
            .flags = .{ .tovol = true },
            .total_volume = total,
        };
    }

    pub fn initUplinkDownlink(ul: u64, dl: u64) VolumeQuota {
        return .{
            .flags = .{ .ulvol = true, .dlvol = true },
            .uplink_volume = ul,
            .downlink_volume = dl,
        };
    }

    pub fn initAll(total: u64, ul: u64, dl: u64) VolumeQuota {
        return .{
            .flags = .{ .tovol = true, .ulvol = true, .dlvol = true },
            .total_volume = total,
            .uplink_volume = ul,
            .downlink_volume = dl,
        };
    }
};

/// Time Quota IE (3GPP TS 29.244 Section 8.2.74)
pub const TimeQuota = struct {
    quota: u32, // seconds

    pub fn init(quota: u32) TimeQuota {
        return .{ .quota = quota };
    }
};

/// RAT Type IE (3GPP TS 29.244 Section 8.2.157)
pub const RatTypeIE = struct {
    rat_type: types.RatType,

    pub fn init(rat_type: types.RatType) RatTypeIE {
        return .{ .rat_type = rat_type };
    }

    pub fn nr() RatTypeIE {
        return .{ .rat_type = .nr };
    }

    pub fn eutran() RatTypeIE {
        return .{ .rat_type = .eutran };
    }

    pub fn wlan() RatTypeIE {
        return .{ .rat_type = .wlan };
    }
};

/// Ethernet PDU Session Information IE (3GPP TS 29.244 Section 8.2.142)
pub const EthernetPduSessionInformation = struct {
    flags: packed struct {
        ethi: bool = false, // Ethernet Header present in uplink
        _spare: u7 = 0,
    },

    pub fn init() EthernetPduSessionInformation {
        return .{ .flags = .{} };
    }

    pub fn withEthernetHeader() EthernetPduSessionInformation {
        return .{ .flags = .{ .ethi = true } };
    }
};

/// MAC Address IE (3GPP TS 29.244 Section 8.2.143)
pub const MacAddress = struct {
    flags: packed struct {
        sour: bool = false, // Source MAC address
        dest: bool = false, // Destination MAC address
        usuo: bool = false, // Upper Source MAC address
        udes: bool = false, // Upper Destination MAC address
        _spare: u4 = 0,
    },
    source_mac: ?[6]u8 = null,
    dest_mac: ?[6]u8 = null,
    upper_source_mac: ?[6]u8 = null,
    upper_dest_mac: ?[6]u8 = null,

    pub fn initSource(mac: [6]u8) MacAddress {
        return .{
            .flags = .{ .sour = true },
            .source_mac = mac,
        };
    }

    pub fn initDest(mac: [6]u8) MacAddress {
        return .{
            .flags = .{ .dest = true },
            .dest_mac = mac,
        };
    }

    pub fn initSourceDest(src: [6]u8, dst: [6]u8) MacAddress {
        return .{
            .flags = .{ .sour = true, .dest = true },
            .source_mac = src,
            .dest_mac = dst,
        };
    }
};

/// C-TAG IE (3GPP TS 29.244 Section 8.2.144)
/// Customer VLAN Tag
pub const CTag = struct {
    flags: packed struct {
        pcp: bool = false, // Priority Code Point present
        dei: bool = false, // Drop Eligible Indicator present
        vid: bool = false, // VLAN ID present
        _spare: u5 = 0,
    },
    cvlan_pcp: ?u3 = null,
    cvlan_dei: ?u1 = null,
    cvlan_vid: ?u12 = null,

    pub fn init(vid: u12) CTag {
        return .{
            .flags = .{ .vid = true },
            .cvlan_vid = vid,
        };
    }

    pub fn initFull(pcp: u3, dei: u1, vid: u12) CTag {
        return .{
            .flags = .{ .pcp = true, .dei = true, .vid = true },
            .cvlan_pcp = pcp,
            .cvlan_dei = dei,
            .cvlan_vid = vid,
        };
    }
};

/// S-TAG IE (3GPP TS 29.244 Section 8.2.145)
/// Service VLAN Tag
pub const STag = struct {
    flags: packed struct {
        pcp: bool = false, // Priority Code Point present
        dei: bool = false, // Drop Eligible Indicator present
        vid: bool = false, // VLAN ID present
        _spare: u5 = 0,
    },
    svlan_pcp: ?u3 = null,
    svlan_dei: ?u1 = null,
    svlan_vid: ?u12 = null,

    pub fn init(vid: u12) STag {
        return .{
            .flags = .{ .vid = true },
            .svlan_vid = vid,
        };
    }

    pub fn initFull(pcp: u3, dei: u1, vid: u12) STag {
        return .{
            .flags = .{ .pcp = true, .dei = true, .vid = true },
            .svlan_pcp = pcp,
            .svlan_dei = dei,
            .svlan_vid = vid,
        };
    }
};

/// Ethertype IE (3GPP TS 29.244 Section 8.2.146)
pub const Ethertype = struct {
    ethertype: u16,

    pub fn init(ethertype: u16) Ethertype {
        return .{ .ethertype = ethertype };
    }

    /// IPv4 (0x0800)
    pub fn ipv4() Ethertype {
        return .{ .ethertype = 0x0800 };
    }

    /// IPv6 (0x86DD)
    pub fn ipv6() Ethertype {
        return .{ .ethertype = 0x86DD };
    }

    /// ARP (0x0806)
    pub fn arp() Ethertype {
        return .{ .ethertype = 0x0806 };
    }

    /// VLAN (0x8100)
    pub fn vlan() Ethertype {
        return .{ .ethertype = 0x8100 };
    }
};

/// Ethernet Packet Filter IE (3GPP TS 29.244 Section 8.2.139)
/// Grouped IE for filtering Ethernet packets
pub const EthernetPacketFilter = struct {
    ethernet_filter_id: ?u32 = null,
    ethernet_filter_properties: ?u8 = null,
    mac_address: ?MacAddress = null,
    ethertype: ?Ethertype = null,
    c_tag: ?CTag = null,
    s_tag: ?STag = null,
    sdf_filter: ?SDFFilter = null,

    pub fn init() EthernetPacketFilter {
        return .{};
    }

    pub fn withMacAddress(self: EthernetPacketFilter, mac: MacAddress) EthernetPacketFilter {
        var result = self;
        result.mac_address = mac;
        return result;
    }

    pub fn withEthertype(self: EthernetPacketFilter, etype: Ethertype) EthernetPacketFilter {
        var result = self;
        result.ethertype = etype;
        return result;
    }

    pub fn withCTag(self: EthernetPacketFilter, ctag: CTag) EthernetPacketFilter {
        var result = self;
        result.c_tag = ctag;
        return result;
    }

    pub fn withSTag(self: EthernetPacketFilter, stag: STag) EthernetPacketFilter {
        var result = self;
        result.s_tag = stag;
        return result;
    }
};

/// QoS Information IE (3GPP TS 29.244 Section 8.2.152)
/// Grouped IE for QoS Flow handling
pub const QosInformation = struct {
    qfi: ?QFI = null,
    qos_priority_level: ?u8 = null,
    averaging_window: ?u32 = null,
    guaranteed_bitrate: ?GBR = null,
    maximum_bitrate: ?MBR = null,

    pub fn init(qfi: QFI) QosInformation {
        return .{ .qfi = qfi };
    }

    pub fn withPriorityLevel(self: QosInformation, priority: u8) QosInformation {
        var result = self;
        result.qos_priority_level = priority;
        return result;
    }

    pub fn withBitrates(self: QosInformation, gbr: GBR, mbr: MBR) QosInformation {
        var result = self;
        result.guaranteed_bitrate = gbr;
        result.maximum_bitrate = mbr;
        return result;
    }
};

/// Create Traffic Endpoint IE (3GPP TS 29.244 Section 8.2.127)
/// Grouped IE for multi-access PDU session support
pub const CreateTrafficEndpoint = struct {
    traffic_endpoint_id: u8,
    f_teid: ?FTEID = null,
    network_instance: ?NetworkInstance = null,
    ue_ip_address: ?UEIPAddress = null,
    ethernet_pdu_session_information: ?EthernetPduSessionInformation = null,
    framed_route: ?[]const u8 = null,
    framed_routing: ?u32 = null,
    framed_ipv6_route: ?[]const u8 = null,

    pub fn init(traffic_endpoint_id: u8) CreateTrafficEndpoint {
        return .{ .traffic_endpoint_id = traffic_endpoint_id };
    }

    pub fn withFTeid(self: CreateTrafficEndpoint, f_teid: FTEID) CreateTrafficEndpoint {
        var result = self;
        result.f_teid = f_teid;
        return result;
    }

    pub fn withUeIp(self: CreateTrafficEndpoint, ue_ip: UEIPAddress) CreateTrafficEndpoint {
        var result = self;
        result.ue_ip_address = ue_ip;
        return result;
    }

    pub fn withEthernetInfo(self: CreateTrafficEndpoint, eth_info: EthernetPduSessionInformation) CreateTrafficEndpoint {
        var result = self;
        result.ethernet_pdu_session_information = eth_info;
        return result;
    }
};

// ============================================================================
// Phase 6: Usage Reporting IEs (Issue #3)
// ============================================================================

/// Volume Measurement IE (3GPP TS 29.244 Section 8.2.40)
/// Reports measured traffic volumes (bytes and packets)
pub const VolumeMeasurement = struct {
    flags: packed struct {
        tovol: bool = false, // Total Volume present
        ulvol: bool = false, // Uplink Volume present
        dlvol: bool = false, // Downlink Volume present
        tonop: bool = false, // Total Number of Packets present
        ulnop: bool = false, // Uplink Number of Packets present
        dlnop: bool = false, // Downlink Number of Packets present
        _spare: u2 = 0,
    },
    total_volume: ?u64 = null,
    uplink_volume: ?u64 = null,
    downlink_volume: ?u64 = null,
    total_packets: ?u64 = null,
    uplink_packets: ?u64 = null,
    downlink_packets: ?u64 = null,

    pub fn init() VolumeMeasurement {
        return .{ .flags = .{} };
    }

    pub fn initTotal(total_bytes: u64) VolumeMeasurement {
        return .{
            .flags = .{ .tovol = true },
            .total_volume = total_bytes,
        };
    }

    pub fn initUplinkDownlink(ul_bytes: u64, dl_bytes: u64) VolumeMeasurement {
        return .{
            .flags = .{ .ulvol = true, .dlvol = true },
            .uplink_volume = ul_bytes,
            .downlink_volume = dl_bytes,
        };
    }

    pub fn initAll(total: u64, ul: u64, dl: u64) VolumeMeasurement {
        return .{
            .flags = .{ .tovol = true, .ulvol = true, .dlvol = true },
            .total_volume = total,
            .uplink_volume = ul,
            .downlink_volume = dl,
        };
    }

    pub fn withPackets(self: VolumeMeasurement, total_pkts: ?u64, ul_pkts: ?u64, dl_pkts: ?u64) VolumeMeasurement {
        var result = self;
        if (total_pkts) |t| {
            result.flags.tonop = true;
            result.total_packets = t;
        }
        if (ul_pkts) |u| {
            result.flags.ulnop = true;
            result.uplink_packets = u;
        }
        if (dl_pkts) |d| {
            result.flags.dlnop = true;
            result.downlink_packets = d;
        }
        return result;
    }
};

/// Duration Measurement IE (3GPP TS 29.244 Section 8.2.41)
/// Reports measured session/measurement duration in seconds
pub const DurationMeasurement = struct {
    duration: u32, // Duration in seconds

    pub fn init(duration: u32) DurationMeasurement {
        return .{ .duration = duration };
    }
};

/// Time of First Packet IE (3GPP TS 29.244 Section 8.2.42)
/// NTP timestamp of when first packet was detected
pub const TimeOfFirstPacket = struct {
    timestamp: u32, // NTP timestamp (seconds since 1900-01-01)

    pub fn init(timestamp: u32) TimeOfFirstPacket {
        return .{ .timestamp = timestamp };
    }

    pub fn fromUnixTime(unix_time: i64) TimeOfFirstPacket {
        const ntp_offset: i64 = 2208988800;
        return .{ .timestamp = @intCast(unix_time + ntp_offset) };
    }
};

/// Time of Last Packet IE (3GPP TS 29.244 Section 8.2.43)
/// NTP timestamp of when last packet was detected
pub const TimeOfLastPacket = struct {
    timestamp: u32, // NTP timestamp (seconds since 1900-01-01)

    pub fn init(timestamp: u32) TimeOfLastPacket {
        return .{ .timestamp = timestamp };
    }

    pub fn fromUnixTime(unix_time: i64) TimeOfLastPacket {
        const ntp_offset: i64 = 2208988800;
        return .{ .timestamp = @intCast(unix_time + ntp_offset) };
    }
};

/// Start Time IE (3GPP TS 29.244 Section 8.2.44)
/// NTP timestamp of measurement period start
pub const StartTime = struct {
    timestamp: u32, // NTP timestamp

    pub fn init(timestamp: u32) StartTime {
        return .{ .timestamp = timestamp };
    }

    pub fn fromUnixTime(unix_time: i64) StartTime {
        const ntp_offset: i64 = 2208988800;
        return .{ .timestamp = @intCast(unix_time + ntp_offset) };
    }
};

/// End Time IE (3GPP TS 29.244 Section 8.2.45)
/// NTP timestamp of measurement period end
pub const EndTime = struct {
    timestamp: u32, // NTP timestamp

    pub fn init(timestamp: u32) EndTime {
        return .{ .timestamp = timestamp };
    }

    pub fn fromUnixTime(unix_time: i64) EndTime {
        const ntp_offset: i64 = 2208988800;
        return .{ .timestamp = @intCast(unix_time + ntp_offset) };
    }
};

/// UR-SEQN (Usage Report Sequence Number) IE (3GPP TS 29.244 Section 8.2.46)
/// Sequence number for usage reports
pub const URSeqn = struct {
    sequence_number: u32,

    pub fn init(seq: u32) URSeqn {
        return .{ .sequence_number = seq };
    }
};

/// Usage Report Trigger IE (3GPP TS 29.244 Section 8.2.47)
/// Indicates what triggered the usage report
pub const UsageReportTrigger = struct {
    flags: packed struct {
        // First byte
        perio: bool = false, // Periodic Reporting
        volth: bool = false, // Volume Threshold
        timth: bool = false, // Time Threshold
        quhti: bool = false, // Quota Holding Time
        start: bool = false, // Start of Traffic
        stopt: bool = false, // Stop of Traffic
        droth: bool = false, // Dropped DL Traffic Threshold
        immer: bool = false, // Immediate Report
        // Second byte
        volqu: bool = false, // Volume Quota
        timqu: bool = false, // Time Quota
        liusa: bool = false, // Linked Usage Reporting
        termr: bool = false, // Termination Report
        monit: bool = false, // Monitoring Time
        envcl: bool = false, // Envelope Closure
        macar: bool = false, // MAC Addresses Reporting
        eveth: bool = false, // Event Threshold
        // Third byte
        evequ: bool = false, // Event Quota
        tebur: bool = false, // Termination By UP Function Report
        ipmjl: bool = false, // IP Multicast Join/Leave
        quvti: bool = false, // Quota Validity Time
        emrre: bool = false, // End Marker Receipt Report
        _spare: u3 = 0,
    },

    pub fn init() UsageReportTrigger {
        return .{ .flags = .{} };
    }

    pub fn periodic() UsageReportTrigger {
        return .{ .flags = .{ .perio = true } };
    }

    pub fn volumeThreshold() UsageReportTrigger {
        return .{ .flags = .{ .volth = true } };
    }

    pub fn timeThreshold() UsageReportTrigger {
        return .{ .flags = .{ .timth = true } };
    }

    pub fn terminationReport() UsageReportTrigger {
        return .{ .flags = .{ .termr = true } };
    }

    pub fn immediateReport() UsageReportTrigger {
        return .{ .flags = .{ .immer = true } };
    }

    pub fn volumeQuota() UsageReportTrigger {
        return .{ .flags = .{ .volqu = true } };
    }

    pub fn timeQuota() UsageReportTrigger {
        return .{ .flags = .{ .timqu = true } };
    }
};

/// Report Type IE (3GPP TS 29.244 Section 8.2.21)
/// Indicates the type of report in a Session Report Request
pub const ReportType = struct {
    flags: packed struct {
        dldr: bool = false, // Downlink Data Report
        usar: bool = false, // Usage Report
        erir: bool = false, // Error Indication Report
        upir: bool = false, // User Plane Inactivity Report
        tmir: bool = false, // TSC Management Information Report
        sesr: bool = false, // Session Report
        uisr: bool = false, // UL/DL Data Status Report
        _spare: u1 = 0,
    },

    pub fn init() ReportType {
        return .{ .flags = .{} };
    }

    pub fn usageReport() ReportType {
        return .{ .flags = .{ .usar = true } };
    }

    pub fn downlinkDataReport() ReportType {
        return .{ .flags = .{ .dldr = true } };
    }

    pub fn errorIndicationReport() ReportType {
        return .{ .flags = .{ .erir = true } };
    }
};

/// Usage Report (Session Report Request) IE (3GPP TS 29.244 Section 8.2.49)
/// Grouped IE containing usage report data for SessionReportRequest
pub const UsageReportSRR = struct {
    urr_id: URRID,
    ur_seqn: URSeqn,
    usage_report_trigger: UsageReportTrigger,
    start_time: ?StartTime = null,
    end_time: ?EndTime = null,
    volume_measurement: ?VolumeMeasurement = null,
    duration_measurement: ?DurationMeasurement = null,
    time_of_first_packet: ?TimeOfFirstPacket = null,
    time_of_last_packet: ?TimeOfLastPacket = null,

    pub fn init(urr_id: URRID, ur_seqn: URSeqn, trigger: UsageReportTrigger) UsageReportSRR {
        return .{
            .urr_id = urr_id,
            .ur_seqn = ur_seqn,
            .usage_report_trigger = trigger,
        };
    }

    pub fn withVolumeMeasurement(self: UsageReportSRR, vm: VolumeMeasurement) UsageReportSRR {
        var result = self;
        result.volume_measurement = vm;
        return result;
    }

    pub fn withDurationMeasurement(self: UsageReportSRR, dm: DurationMeasurement) UsageReportSRR {
        var result = self;
        result.duration_measurement = dm;
        return result;
    }

    pub fn withTimeRange(self: UsageReportSRR, start: StartTime, end: EndTime) UsageReportSRR {
        var result = self;
        result.start_time = start;
        result.end_time = end;
        return result;
    }

    pub fn withPacketTimes(self: UsageReportSRR, first: TimeOfFirstPacket, last: TimeOfLastPacket) UsageReportSRR {
        var result = self;
        result.time_of_first_packet = first;
        result.time_of_last_packet = last;
        return result;
    }
};

/// Usage Report (Session Deletion Response) IE (3GPP TS 29.244 Section 8.2.50)
/// Grouped IE containing usage report data for SessionDeletionResponse
pub const UsageReportSDR = struct {
    urr_id: URRID,
    ur_seqn: URSeqn,
    usage_report_trigger: UsageReportTrigger,
    start_time: ?StartTime = null,
    end_time: ?EndTime = null,
    volume_measurement: ?VolumeMeasurement = null,
    duration_measurement: ?DurationMeasurement = null,
    time_of_first_packet: ?TimeOfFirstPacket = null,
    time_of_last_packet: ?TimeOfLastPacket = null,

    pub fn init(urr_id: URRID, ur_seqn: URSeqn, trigger: UsageReportTrigger) UsageReportSDR {
        return .{
            .urr_id = urr_id,
            .ur_seqn = ur_seqn,
            .usage_report_trigger = trigger,
        };
    }

    pub fn withVolumeMeasurement(self: UsageReportSDR, vm: VolumeMeasurement) UsageReportSDR {
        var result = self;
        result.volume_measurement = vm;
        return result;
    }

    pub fn withDurationMeasurement(self: UsageReportSDR, dm: DurationMeasurement) UsageReportSDR {
        var result = self;
        result.duration_measurement = dm;
        return result;
    }

    pub fn withTimeRange(self: UsageReportSDR, start: StartTime, end: EndTime) UsageReportSDR {
        var result = self;
        result.start_time = start;
        result.end_time = end;
        return result;
    }
};

/// Usage Report (Session Modification Response) IE (3GPP TS 29.244 Section 8.2.51)
/// Grouped IE containing usage report data for SessionModificationResponse
pub const UsageReportSMR = struct {
    urr_id: URRID,
    ur_seqn: URSeqn,
    usage_report_trigger: UsageReportTrigger,
    start_time: ?StartTime = null,
    end_time: ?EndTime = null,
    volume_measurement: ?VolumeMeasurement = null,
    duration_measurement: ?DurationMeasurement = null,
    time_of_first_packet: ?TimeOfFirstPacket = null,
    time_of_last_packet: ?TimeOfLastPacket = null,

    pub fn init(urr_id: URRID, ur_seqn: URSeqn, trigger: UsageReportTrigger) UsageReportSMR {
        return .{
            .urr_id = urr_id,
            .ur_seqn = ur_seqn,
            .usage_report_trigger = trigger,
        };
    }

    pub fn withVolumeMeasurement(self: UsageReportSMR, vm: VolumeMeasurement) UsageReportSMR {
        var result = self;
        result.volume_measurement = vm;
        return result;
    }

    pub fn withDurationMeasurement(self: UsageReportSMR, dm: DurationMeasurement) UsageReportSMR {
        var result = self;
        result.duration_measurement = dm;
        return result;
    }

    pub fn withTimeRange(self: UsageReportSMR, start: StartTime, end: EndTime) UsageReportSMR {
        var result = self;
        result.start_time = start;
        result.end_time = end;
        return result;
    }
};

/// Downlink Data Report IE (3GPP TS 29.244 Section 8.2.22)
/// Grouped IE for downlink data notification
pub const DownlinkDataReport = struct {
    pdr_id: ?PDRID = null,
    downlink_data_service_information: ?[]const u8 = null,

    pub fn init() DownlinkDataReport {
        return .{};
    }

    pub fn withPdrId(self: DownlinkDataReport, pdr_id: PDRID) DownlinkDataReport {
        var result = self;
        result.pdr_id = pdr_id;
        return result;
    }
};

/// Error Indication Report IE (3GPP TS 29.244 Section 8.2.23)
/// Grouped IE for error indication reporting
pub const ErrorIndicationReport = struct {
    f_teid: ?FTEID = null,

    pub fn init() ErrorIndicationReport {
        return .{};
    }

    pub fn withFTeid(self: ErrorIndicationReport, f_teid: FTEID) ErrorIndicationReport {
        var result = self;
        result.f_teid = f_teid;
        return result;
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

// ============================================================================
// Phase 5 Tests
// ============================================================================

test "S-NSSAI initialization" {
    // Basic SST only
    const snssai_basic = SNSSAI.init(1);
    try std.testing.expectEqual(@as(u8, 1), snssai_basic.sst);
    try std.testing.expect(snssai_basic.sd == null);

    // With SD
    const snssai_with_sd = SNSSAI.initWithSd(2, 0x123456);
    try std.testing.expectEqual(@as(u8, 2), snssai_with_sd.sst);
    try std.testing.expectEqual(@as(u24, 0x123456), snssai_with_sd.sd.?);

    // Standard slices
    const embb = SNSSAI.embb();
    try std.testing.expectEqual(@as(u8, 1), embb.sst);

    const urllc = SNSSAI.urllc();
    try std.testing.expectEqual(@as(u8, 2), urllc.sst);

    const miot = SNSSAI.miot();
    try std.testing.expectEqual(@as(u8, 3), miot.sst);
}

test "PDU Session Type" {
    const ipv4_session = PduSessionType.ipv4();
    try std.testing.expectEqual(types.PduSessionType.ipv4, ipv4_session.pdu_session_type);

    const ipv6_session = PduSessionType.ipv6();
    try std.testing.expectEqual(types.PduSessionType.ipv6, ipv6_session.pdu_session_type);

    const ipv4v6_session = PduSessionType.ipv4v6();
    try std.testing.expectEqual(types.PduSessionType.ipv4v6, ipv4v6_session.pdu_session_type);

    const ethernet_session = PduSessionType.ethernet();
    try std.testing.expectEqual(types.PduSessionType.ethernet, ethernet_session.pdu_session_type);

    const unstructured_session = PduSessionType.unstructured();
    try std.testing.expectEqual(types.PduSessionType.unstructured, unstructured_session.pdu_session_type);
}

test "QFI (QoS Flow Identifier)" {
    const qfi = QFI.init(9);
    try std.testing.expectEqual(@as(u6, 9), qfi.qfi);

    // Valid range is 0-63 for 6 bits
    const max_qfi = QFI.init(63);
    try std.testing.expectEqual(@as(u6, 63), max_qfi.qfi);
}

test "Volume Quota" {
    // Total volume only
    const quota_total = VolumeQuota.initTotal(5_000_000_000); // 5 GB
    try std.testing.expect(quota_total.flags.tovol);
    try std.testing.expect(!quota_total.flags.ulvol);
    try std.testing.expect(!quota_total.flags.dlvol);
    try std.testing.expectEqual(@as(u64, 5_000_000_000), quota_total.total_volume.?);

    // UL/DL volumes
    const quota_ul_dl = VolumeQuota.initUplinkDownlink(1_000_000_000, 2_000_000_000);
    try std.testing.expect(!quota_ul_dl.flags.tovol);
    try std.testing.expect(quota_ul_dl.flags.ulvol);
    try std.testing.expect(quota_ul_dl.flags.dlvol);
    try std.testing.expectEqual(@as(u64, 1_000_000_000), quota_ul_dl.uplink_volume.?);
    try std.testing.expectEqual(@as(u64, 2_000_000_000), quota_ul_dl.downlink_volume.?);

    // All three
    const quota_all = VolumeQuota.initAll(5_000_000_000, 2_000_000_000, 3_000_000_000);
    try std.testing.expect(quota_all.flags.tovol);
    try std.testing.expect(quota_all.flags.ulvol);
    try std.testing.expect(quota_all.flags.dlvol);
    try std.testing.expectEqual(@as(u64, 5_000_000_000), quota_all.total_volume.?);
    try std.testing.expectEqual(@as(u64, 2_000_000_000), quota_all.uplink_volume.?);
    try std.testing.expectEqual(@as(u64, 3_000_000_000), quota_all.downlink_volume.?);
}

test "Time Quota" {
    const quota = TimeQuota.init(3600); // 1 hour
    try std.testing.expectEqual(@as(u32, 3600), quota.quota);
}

test "RAT Type" {
    const nr_rat = RatTypeIE.nr();
    try std.testing.expectEqual(types.RatType.nr, nr_rat.rat_type);

    const eutran_rat = RatTypeIE.eutran();
    try std.testing.expectEqual(types.RatType.eutran, eutran_rat.rat_type);

    const wlan_rat = RatTypeIE.wlan();
    try std.testing.expectEqual(types.RatType.wlan, wlan_rat.rat_type);
}

test "Ethernet PDU Session Information" {
    const basic_info = EthernetPduSessionInformation.init();
    try std.testing.expect(!basic_info.flags.ethi);

    const with_header = EthernetPduSessionInformation.withEthernetHeader();
    try std.testing.expect(with_header.flags.ethi);
}

test "MAC Address" {
    const src_mac = [_]u8{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 };
    const dst_mac = [_]u8{ 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF };

    const mac_src = MacAddress.initSource(src_mac);
    try std.testing.expect(mac_src.flags.sour);
    try std.testing.expect(!mac_src.flags.dest);
    try std.testing.expectEqualSlices(u8, &src_mac, &mac_src.source_mac.?);

    const mac_dst = MacAddress.initDest(dst_mac);
    try std.testing.expect(!mac_dst.flags.sour);
    try std.testing.expect(mac_dst.flags.dest);
    try std.testing.expectEqualSlices(u8, &dst_mac, &mac_dst.dest_mac.?);

    const mac_both = MacAddress.initSourceDest(src_mac, dst_mac);
    try std.testing.expect(mac_both.flags.sour);
    try std.testing.expect(mac_both.flags.dest);
    try std.testing.expectEqualSlices(u8, &src_mac, &mac_both.source_mac.?);
    try std.testing.expectEqualSlices(u8, &dst_mac, &mac_both.dest_mac.?);
}

test "C-TAG (Customer VLAN Tag)" {
    const vlan_id: u12 = 100;
    const ctag_basic = CTag.init(vlan_id);
    try std.testing.expect(!ctag_basic.flags.pcp);
    try std.testing.expect(!ctag_basic.flags.dei);
    try std.testing.expect(ctag_basic.flags.vid);
    try std.testing.expectEqual(vlan_id, ctag_basic.cvlan_vid.?);

    const pcp: u3 = 5;
    const dei: u1 = 1;
    const ctag_full = CTag.initFull(pcp, dei, vlan_id);
    try std.testing.expect(ctag_full.flags.pcp);
    try std.testing.expect(ctag_full.flags.dei);
    try std.testing.expect(ctag_full.flags.vid);
    try std.testing.expectEqual(pcp, ctag_full.cvlan_pcp.?);
    try std.testing.expectEqual(dei, ctag_full.cvlan_dei.?);
    try std.testing.expectEqual(vlan_id, ctag_full.cvlan_vid.?);
}

test "S-TAG (Service VLAN Tag)" {
    const vlan_id: u12 = 200;
    const stag_basic = STag.init(vlan_id);
    try std.testing.expect(!stag_basic.flags.pcp);
    try std.testing.expect(!stag_basic.flags.dei);
    try std.testing.expect(stag_basic.flags.vid);
    try std.testing.expectEqual(vlan_id, stag_basic.svlan_vid.?);

    const pcp: u3 = 7;
    const dei: u1 = 0;
    const stag_full = STag.initFull(pcp, dei, vlan_id);
    try std.testing.expect(stag_full.flags.pcp);
    try std.testing.expect(stag_full.flags.dei);
    try std.testing.expect(stag_full.flags.vid);
    try std.testing.expectEqual(pcp, stag_full.svlan_pcp.?);
    try std.testing.expectEqual(dei, stag_full.svlan_dei.?);
    try std.testing.expectEqual(vlan_id, stag_full.svlan_vid.?);
}

test "Ethertype" {
    const eth_ipv4 = Ethertype.ipv4();
    try std.testing.expectEqual(@as(u16, 0x0800), eth_ipv4.ethertype);

    const eth_ipv6 = Ethertype.ipv6();
    try std.testing.expectEqual(@as(u16, 0x86DD), eth_ipv6.ethertype);

    const eth_arp = Ethertype.arp();
    try std.testing.expectEqual(@as(u16, 0x0806), eth_arp.ethertype);

    const eth_vlan = Ethertype.vlan();
    try std.testing.expectEqual(@as(u16, 0x8100), eth_vlan.ethertype);

    const custom = Ethertype.init(0x88CC); // LLDP
    try std.testing.expectEqual(@as(u16, 0x88CC), custom.ethertype);
}

test "Ethernet Packet Filter with builder pattern" {
    const src_mac = [_]u8{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 };
    const dst_mac = [_]u8{ 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF };
    const mac_filter = MacAddress.initSourceDest(src_mac, dst_mac);

    const filter = EthernetPacketFilter.init()
        .withMacAddress(mac_filter)
        .withEthertype(Ethertype.ipv4())
        .withCTag(CTag.init(100));

    try std.testing.expect(filter.mac_address != null);
    try std.testing.expect(filter.ethertype != null);
    try std.testing.expect(filter.c_tag != null);
    try std.testing.expectEqual(@as(u16, 0x0800), filter.ethertype.?.ethertype);
    try std.testing.expectEqual(@as(u12, 100), filter.c_tag.?.cvlan_vid.?);
}

test "QoS Information with builder pattern" {
    const qfi = QFI.init(9);
    const priority: u8 = 5;
    const gbr = GBR.init(50_000_000, 100_000_000); // 50 Mbps UL, 100 Mbps DL
    const mbr = MBR.init(100_000_000, 200_000_000); // 100 Mbps UL, 200 Mbps DL

    const qos_info = QosInformation.init(qfi)
        .withPriorityLevel(priority)
        .withBitrates(gbr, mbr);

    try std.testing.expect(qos_info.qfi != null);
    try std.testing.expectEqual(@as(u6, 9), qos_info.qfi.?.qfi);
    try std.testing.expect(qos_info.qos_priority_level != null);
    try std.testing.expectEqual(priority, qos_info.qos_priority_level.?);
    try std.testing.expect(qos_info.guaranteed_bitrate != null);
    try std.testing.expect(qos_info.maximum_bitrate != null);
    try std.testing.expectEqual(@as(u64, 50_000_000), qos_info.guaranteed_bitrate.?.ul_gbr);
    try std.testing.expectEqual(@as(u64, 100_000_000), qos_info.guaranteed_bitrate.?.dl_gbr);
    try std.testing.expectEqual(@as(u64, 100_000_000), qos_info.maximum_bitrate.?.ul_mbr);
    try std.testing.expectEqual(@as(u64, 200_000_000), qos_info.maximum_bitrate.?.dl_mbr);
}

test "Create Traffic Endpoint for multi-access" {
    const endpoint_id: u8 = 1;
    const f_teid = FTEID.initV4(0x12345678, [_]u8{ 10, 0, 0, 1 });
    const ue_ip = UEIPAddress.initIpv4([_]u8{ 172, 16, 0, 1 }, false);

    const endpoint = CreateTrafficEndpoint.init(endpoint_id)
        .withFTeid(f_teid)
        .withUeIp(ue_ip);

    try std.testing.expectEqual(endpoint_id, endpoint.traffic_endpoint_id);
    try std.testing.expect(endpoint.f_teid != null);
    try std.testing.expect(endpoint.ue_ip_address != null);
    try std.testing.expect(endpoint.f_teid.?.flags.v4);
    try std.testing.expectEqual(@as(u32, 0x12345678), endpoint.f_teid.?.teid);
}

test "Create Traffic Endpoint for Ethernet" {
    const endpoint_id: u8 = 2;
    const eth_info = EthernetPduSessionInformation.withEthernetHeader();

    const endpoint = CreateTrafficEndpoint.init(endpoint_id)
        .withEthernetInfo(eth_info);

    try std.testing.expectEqual(endpoint_id, endpoint.traffic_endpoint_id);
    try std.testing.expect(endpoint.ethernet_pdu_session_information != null);
    try std.testing.expect(endpoint.ethernet_pdu_session_information.?.flags.ethi);
}

// ============================================================================
// Phase 6 Tests: Usage Reporting IEs
// ============================================================================

test "Volume Measurement initialization" {
    // Total volume only
    const vm_total = VolumeMeasurement.initTotal(1_000_000_000);
    try std.testing.expect(vm_total.flags.tovol);
    try std.testing.expect(!vm_total.flags.ulvol);
    try std.testing.expect(!vm_total.flags.dlvol);
    try std.testing.expectEqual(@as(u64, 1_000_000_000), vm_total.total_volume.?);

    // UL/DL volumes
    const vm_ul_dl = VolumeMeasurement.initUplinkDownlink(500_000_000, 750_000_000);
    try std.testing.expect(!vm_ul_dl.flags.tovol);
    try std.testing.expect(vm_ul_dl.flags.ulvol);
    try std.testing.expect(vm_ul_dl.flags.dlvol);
    try std.testing.expectEqual(@as(u64, 500_000_000), vm_ul_dl.uplink_volume.?);
    try std.testing.expectEqual(@as(u64, 750_000_000), vm_ul_dl.downlink_volume.?);

    // All volumes with packet counts
    const vm_all = VolumeMeasurement.initAll(1_250_000_000, 500_000_000, 750_000_000)
        .withPackets(10000, 4000, 6000);
    try std.testing.expect(vm_all.flags.tovol);
    try std.testing.expect(vm_all.flags.ulvol);
    try std.testing.expect(vm_all.flags.dlvol);
    try std.testing.expect(vm_all.flags.tonop);
    try std.testing.expect(vm_all.flags.ulnop);
    try std.testing.expect(vm_all.flags.dlnop);
    try std.testing.expectEqual(@as(u64, 10000), vm_all.total_packets.?);
}

test "Duration Measurement" {
    const dm = DurationMeasurement.init(3600); // 1 hour
    try std.testing.expectEqual(@as(u32, 3600), dm.duration);
}

test "Usage Report Trigger flags" {
    const periodic = UsageReportTrigger.periodic();
    try std.testing.expect(periodic.flags.perio);

    const vol_th = UsageReportTrigger.volumeThreshold();
    try std.testing.expect(vol_th.flags.volth);

    const termination = UsageReportTrigger.terminationReport();
    try std.testing.expect(termination.flags.termr);
}

test "Report Type flags" {
    const usage = ReportType.usageReport();
    try std.testing.expect(usage.flags.usar);
    try std.testing.expect(!usage.flags.dldr);

    const dldr = ReportType.downlinkDataReport();
    try std.testing.expect(dldr.flags.dldr);
    try std.testing.expect(!dldr.flags.usar);

    const error_ind = ReportType.errorIndicationReport();
    try std.testing.expect(error_ind.flags.erir);
}

test "Usage Report SRR with builder pattern" {
    const urr_id = URRID.init(1);
    const ur_seqn = URSeqn.init(100);
    const trigger = UsageReportTrigger.periodic();
    const start = StartTime.init(3818692800); // Some NTP timestamp
    const end = EndTime.init(3818696400);
    const vm = VolumeMeasurement.initAll(1_000_000_000, 400_000_000, 600_000_000);
    const dm = DurationMeasurement.init(3600);

    const report = UsageReportSRR.init(urr_id, ur_seqn, trigger)
        .withVolumeMeasurement(vm)
        .withDurationMeasurement(dm)
        .withTimeRange(start, end);

    try std.testing.expectEqual(@as(u32, 1), report.urr_id.urr_id);
    try std.testing.expectEqual(@as(u32, 100), report.ur_seqn.sequence_number);
    try std.testing.expect(report.usage_report_trigger.flags.perio);
    try std.testing.expect(report.volume_measurement != null);
    try std.testing.expect(report.duration_measurement != null);
    try std.testing.expectEqual(@as(u32, 3600), report.duration_measurement.?.duration);
    try std.testing.expect(report.start_time != null);
    try std.testing.expect(report.end_time != null);
}

test "Usage Report SDR for session deletion" {
    const urr_id = URRID.init(2);
    const ur_seqn = URSeqn.init(50);
    const trigger = UsageReportTrigger.terminationReport();
    const vm = VolumeMeasurement.initTotal(5_000_000_000);

    const report = UsageReportSDR.init(urr_id, ur_seqn, trigger)
        .withVolumeMeasurement(vm);

    try std.testing.expectEqual(@as(u32, 2), report.urr_id.urr_id);
    try std.testing.expect(report.usage_report_trigger.flags.termr);
    try std.testing.expect(report.volume_measurement != null);
}

test "Downlink Data Report" {
    const pdr_id = PDRID.init(5);
    const report = DownlinkDataReport.init().withPdrId(pdr_id);

    try std.testing.expect(report.pdr_id != null);
    try std.testing.expectEqual(@as(u16, 5), report.pdr_id.?.rule_id);
}

test "Error Indication Report" {
    const f_teid = FTEID.initV4(0xDEADBEEF, [_]u8{ 192, 168, 1, 100 });
    const report = ErrorIndicationReport.init().withFTeid(f_teid);

    try std.testing.expect(report.f_teid != null);
    try std.testing.expectEqual(@as(u32, 0xDEADBEEF), report.f_teid.?.teid);
}
