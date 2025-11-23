const std = @import("std");

/// PFCP Protocol Version (currently version 1)
pub const PFCP_VERSION: u8 = 1;

/// Default PFCP UDP port (8805)
pub const PFCP_PORT: u16 = 8805;

/// PFCP Message Header (3GPP TS 29.244 Section 7.2.2)
pub const PfcpHeader = struct {
    /// Spare bits (must be 0)
    spare: u4 = 0,
    /// Version (set to PFCP_VERSION)
    version: u4 = PFCP_VERSION,
    /// Spare bit (must be 0)
    spare2: u2 = 0,
    /// Message Priority
    mp: bool = false,
    /// SEID (Session Endpoint Identifier) present flag
    s: bool,
    /// Message type
    message_type: u8,
    /// Total message length (excluding the mandatory part of the header)
    message_length: u16,
    /// Session Endpoint Identifier (present if S flag is set)
    seid: ?u64 = null,
    /// Sequence number
    sequence_number: u24,
    /// Spare bits
    spare3: u8 = 0,

    pub fn init(message_type: MessageType, has_seid: bool) PfcpHeader {
        return .{
            .s = has_seid,
            .message_type = @intFromEnum(message_type),
            .message_length = 0, // Will be calculated during serialization
            .seid = if (has_seid) 0 else null,
            .sequence_number = 0,
        };
    }

    pub fn getHeaderLength(self: PfcpHeader) usize {
        // Base header: 4 bytes (version + flags + type + length)
        // SEID: 8 bytes if present
        // Sequence number: 3 bytes
        // Spare: 1 byte
        return if (self.s) 16 else 8;
    }
};

/// PFCP Message Types (3GPP TS 29.244 Section 7.4.2)
pub const MessageType = enum(u8) {
    // Node related messages (1-9)
    heartbeat_request = 1,
    heartbeat_response = 2,
    pfd_management_request = 3,
    pfd_management_response = 4,
    association_setup_request = 5,
    association_setup_response = 6,
    association_update_request = 7,
    association_update_response = 8,
    association_release_request = 9,
    association_release_response = 10,
    version_not_supported_response = 11,
    node_report_request = 12,
    node_report_response = 13,
    session_set_deletion_request = 14,
    session_set_deletion_response = 15,

    // Session related messages (50-99)
    session_establishment_request = 50,
    session_establishment_response = 51,
    session_modification_request = 52,
    session_modification_response = 53,
    session_deletion_request = 54,
    session_deletion_response = 55,
    session_report_request = 56,
    session_report_response = 57,

    _,

    pub fn hasSession(self: MessageType) bool {
        return @intFromEnum(self) >= 50;
    }
};

/// Information Element Types (3GPP TS 29.244 Section 8.2)
pub const IEType = enum(u16) {
    create_pdr = 1,
    pdi = 2,
    create_far = 3,
    forwarding_parameters = 4,
    duplicating_parameters = 5,
    create_urr = 6,
    create_qer = 7,
    created_pdr = 8,
    update_pdr = 9,
    update_far = 10,
    update_forwarding_parameters = 11,
    update_bar_response = 12,
    update_urr = 13,
    update_qer = 14,
    remove_pdr = 15,
    remove_far = 16,
    remove_urr = 17,
    remove_qer = 18,
    cause = 19,
    source_interface = 20,
    f_teid = 21,
    network_instance = 22,
    sdf_filter = 23,
    application_id = 24,
    gate_status = 25,
    mbr = 26,
    gbr = 27,
    qer_correlation_id = 28,
    precedence = 29,
    transport_level_marking = 30,
    volume_threshold = 31,
    time_threshold = 32,
    monitoring_time = 33,
    subsequent_volume_threshold = 34,
    subsequent_time_threshold = 35,
    inactivity_detection_time = 36,
    reporting_triggers = 37,
    redirect_information = 38,
    report_type = 39,
    offending_ie = 40,
    forwarding_policy = 41,
    destination_interface = 42,
    up_function_features = 43,
    apply_action = 44,
    downlink_data_service_information = 45,
    downlink_data_notification_delay = 46,
    dl_buffering_duration = 47,
    dl_buffering_suggested_packet_count = 48,
    pfcpsmreq_flags = 49,
    pfcpsrrsp_flags = 50,
    load_control_information = 51,
    sequence_number = 52,
    metric = 53,
    overload_control_information = 54,
    timer = 55,
    pdr_id = 56,
    f_seid = 57,
    application_ids_pfds = 58,
    pfd_context = 59,
    node_id = 60,
    pfd_contents = 61,
    measurement_method = 62,
    usage_report_trigger = 63,
    measurement_period = 64,
    fq_csid = 65,
    volume_measurement = 66,
    duration_measurement = 67,
    application_detection_information = 68,
    time_of_first_packet = 69,
    time_of_last_packet = 70,
    quota_holding_time = 71,
    dropped_dl_traffic_threshold = 72,
    volume_quota = 73,
    time_quota = 74,
    start_time = 75,
    end_time = 76,
    query_urr = 77,
    usage_report_smr = 78,
    usage_report_sdr = 79,
    usage_report_srr = 80,
    urr_id = 81,
    linked_urr_id = 82,
    downlink_data_report = 83,
    outer_header_creation = 84,
    create_bar = 85,
    update_bar_smr = 86,
    remove_bar = 87,
    bar_id = 88,
    cp_function_features = 89,
    usage_information = 90,
    application_instance_id = 91,
    flow_information = 92,
    ue_ip_address = 93,
    packet_rate = 94,
    outer_header_removal = 95,
    recovery_time_stamp = 96,
    dl_flow_level_marking = 97,
    header_enrichment = 98,
    error_indication_report = 99,
    measurement_information = 100,
    // IE types 101-123 (3GPP TS 29.244 Section 8.2)
    node_report_type = 101,
    user_plane_path_failure_report_ie_smr = 102,
    remote_gtp_u_peer = 103,
    ur_seqn = 104,
    update_duplicating_parameters = 105,
    activate_predefined_rules = 106,
    deactivate_predefined_rules = 107,
    far_id = 108,
    qer_id = 109,
    oci_flags = 110,
    pfcp_association_release_request = 111,
    graceful_release_period = 112,
    pdn_type = 113,
    failed_rule_id = 114,
    time_quota_mechanism = 115,
    user_plane_ip_resource_information = 116,
    user_plane_inactivity_timer = 117,
    aggregated_urrs = 118,
    multiplier = 119,
    aggregated_urr_id = 120,
    subsequent_volume_quota = 121,
    subsequent_time_quota = 122,
    rqi = 123,
    // IE types 124+ (3GPP TS 29.244 Section 8.2)
    qfi = 124,
    query_urr_reference = 125,
    additional_usage_reports_information = 126,
    create_traffic_endpoint = 127,
    created_traffic_endpoint = 128,
    update_traffic_endpoint = 129,
    remove_traffic_endpoint = 130,
    traffic_endpoint_id = 131,
    ethernet_packet_filter = 132,
    mac_address = 133,
    c_tag = 134,
    s_tag = 135,
    ethertype = 136,
    proxying = 137,
    ethernet_filter_id = 138,
    ethernet_filter_properties = 139,
    suggested_buffering_packets_count = 140,
    user_id = 141,
    ethernet_pdu_session_information = 142,
    ethernet_traffic_information = 143,
    mac_addresses_detected = 144,
    mac_addresses_removed = 145,
    ethernet_inactivity_timer = 146,
    additional_monitoring_time = 147,
    event_quota = 148,
    event_threshold = 149,
    subsequent_event_quota = 150,
    subsequent_event_threshold = 151,
    trace_information = 152,
    framed_route = 153,
    framed_routing = 154,
    framed_ipv6_route = 155,
    event_time_stamp = 156,
    averaging_window = 157,
    paging_policy_indicator = 158,
    apn_dnn = 159,
    tgpp_interface_type = 160,
    pfcpsr_req_flags = 161,
    pfcpau_req_flags = 162,
    activation_time = 163,
    deactivation_time = 164,
    create_mar = 165,
    tgpp_access_forwarding_action_information = 166,
    non_tgpp_access_forwarding_action_information = 167,
    remove_mar = 168,
    update_mar = 169,
    mar_id = 170,
    steering_functionality = 171,
    steering_mode = 172,
    weight = 173,
    priority = 174,
    update_tgpp_access_forwarding_action_information = 175,
    update_non_tgpp_access_forwarding_action_information = 176,
    ue_ip_address_pool_identity = 177,
    alternative_smf_ip_address = 178,
    packet_replication_and_detection_carry_on_information = 179,
    smf_set_id = 180,
    quota_validity_time = 181,
    number_of_reports = 182,
    pfcp_session_retention_information = 183,
    pfcpas_rsp_flags = 184,
    cp_pfcp_entity_ip_address = 185,
    pfcpse_req_flags = 186,
    user_plane_path_recovery_report = 187,
    ip_multicast_addressing_info = 188,
    join_ip_multicast_information_within_usage_report = 189,
    leave_ip_multicast_information_within_usage_report = 190,
    ip_multicast_address = 191,
    source_ip_address = 192,
    packet_rate_status = 193,
    create_bridge_info_for_tsc = 194,
    created_bridge_info_for_tsc = 195,
    dstt_port_number = 196,
    nwtt_port_number = 197,
    tsn_bridge_id = 198,
    tsc_management_information_within_session_modification_request = 199,
    tsc_management_information_within_session_modification_response = 200,
    tsc_management_information_within_session_report_request = 201,
    port_management_information_container = 202,
    clock_drift_control_information = 203,
    requested_clock_drift_information = 204,
    clock_drift_report = 205,
    tsn_time_domain_number = 206,
    time_offset_threshold = 207,
    cumulative_rate_ratio_threshold = 208,
    time_offset_measurement = 209,
    cumulative_rate_ratio_measurement = 210,
    remove_srr = 211,
    create_srr = 212,
    update_srr = 213,
    session_report = 214,
    srr_id = 215,
    access_availability_control_information = 216,
    requested_access_availability_information = 217,
    access_availability_report = 218,
    access_availability_information = 219,
    provide_atsss_control_information = 220,
    atsss_control_parameters = 221,
    mptcp_control_information = 222,
    atsss_ll_control_information = 223,
    pmf_control_information = 224,
    mptcp_parameters = 225,
    atsss_ll_parameters = 226,
    pmf_parameters = 227,
    mptcp_address_information = 228,
    ue_link_specific_ip_address = 229,
    pmf_address_information = 230,
    atsss_ll_information = 231,
    data_network_access_identifier = 232,
    ue_ip_address_pool_information = 233,
    average_packet_delay = 234,
    minimum_packet_delay = 235,
    maximum_packet_delay = 236,
    qos_report_trigger = 237,
    gtp_u_path_qos_control_information = 238,
    gtp_u_path_qos_report = 239,
    qos_information_in_gtp_u_path_qos_report = 240,
    gtp_u_path_interface_type = 241,
    qos_monitoring_per_qos_flow_control_information = 242,
    requested_qos_monitoring = 243,
    reporting_frequency = 244,
    packet_delay_thresholds = 245,
    minimum_wait_time = 246,
    qos_monitoring_report = 247,
    qos_monitoring_measurement = 248,
    mt_edt_control_information = 249,
    dl_data_packets_size = 250,
    qer_control_indications = 251,
    packet_rate_status_report = 252,
    nf_instance_id = 253,
    ethernet_context_information = 254,
    redundant_transmission_parameters = 255,
    updated_pdr = 256,
    s_nssai = 257,
    ip_version = 258,
    pfcpas_req_flags = 259,
    data_status = 260,
    provide_rds_configuration_information = 261,
    rds_configuration_information = 262,
    query_packet_rate_status_within_session_modification_request = 263,
    packet_rate_status_report_within_session_modification_response = 264,
    mptcp_applicable_indication = 265,
    bridge_management_information_container = 266,
    ue_ip_address_usage_information = 267,
    number_of_ue_ip_addresses = 268,
    validity_timer = 269,
    redundant_transmission_forwarding_parameters = 270,
    transport_delay_reporting = 271,

    _,
};

/// Node ID Type (3GPP TS 29.244 Section 8.2.38)
pub const NodeIdType = enum(u4) {
    ipv4 = 0,
    ipv6 = 1,
    fqdn = 2,
    _,
};

/// Cause Values (3GPP TS 29.244 Section 8.2.1)
pub const CauseValue = enum(u8) {
    // Success
    request_accepted = 1,
    more_usage_report_to_send = 2,

    // Request rejected
    request_rejected = 64,
    session_context_not_found = 65,
    mandatory_ie_missing = 66,
    conditional_ie_missing = 67,
    invalid_length = 68,
    mandatory_ie_incorrect = 69,
    invalid_forwarding_policy = 70,
    invalid_f_teid_allocation_option = 71,
    no_established_pfcp_association = 72,
    rule_creation_modification_failure = 73,
    pfcp_entity_in_congestion = 74,
    no_resources_available = 75,
    service_not_supported = 76,
    system_failure = 77,
    redirection_requested = 78,
    all_dynamic_addresses_occupied = 79,

    _,

    pub fn isAccepted(self: CauseValue) bool {
        return @intFromEnum(self) < 64;
    }
};

/// Source Interface (3GPP TS 29.244 Section 8.2.2)
pub const SourceInterface = enum(u4) {
    access = 0,
    core = 1,
    sgi_lan = 2,
    cp_function = 3,
    _,
};

/// Destination Interface (3GPP TS 29.244 Section 8.2.14)
pub const DestinationInterface = enum(u4) {
    access = 0,
    core = 1,
    sgi_lan = 2,
    cp_function = 3,
    li_function = 4,
    _,
};

/// Apply Action flags (3GPP TS 29.244 Section 8.2.25)
pub const ApplyAction = packed struct {
    drop: bool = false,
    forw: bool = false,
    buff: bool = false,
    nocp: bool = false,
    dupl: bool = false,
    ipma: bool = false,
    ipmd: bool = false,
    dfrt: bool = false,
    edrt: bool = false,
    bdpn: bool = false,
    ddpn: bool = false,
    _spare: u5 = 0,
};

/// PDU Session Type (3GPP TS 29.244 Section 8.2.125)
pub const PduSessionType = enum(u4) {
    ipv4 = 1,
    ipv6 = 2,
    ipv4v6 = 3,
    unstructured = 4,
    ethernet = 5,
    _,
};

/// RAT Type (3GPP TS 29.244 Section 8.2.157)
pub const RatType = enum(u8) {
    utran = 1,
    geran = 2,
    wlan = 3,
    gan = 4,
    hspa_evolution = 5,
    eutran = 6,
    virtual = 7,
    eutran_nb_iot = 8,
    lte_m = 9,
    nr = 10,
    _,
};

test "PFCP Header size" {
    const header_no_seid = PfcpHeader.init(.heartbeat_request, false);
    try std.testing.expectEqual(@as(usize, 8), header_no_seid.getHeaderLength());

    const header_with_seid = PfcpHeader.init(.session_establishment_request, true);
    try std.testing.expectEqual(@as(usize, 16), header_with_seid.getHeaderLength());
}

test "Message type session detection" {
    try std.testing.expect(!MessageType.heartbeat_request.hasSession());
    try std.testing.expect(!MessageType.association_setup_request.hasSession());
    try std.testing.expect(MessageType.session_establishment_request.hasSession());
    try std.testing.expect(MessageType.session_modification_request.hasSession());
}

test "Cause value acceptance" {
    try std.testing.expect(CauseValue.request_accepted.isAccepted());
    try std.testing.expect(!CauseValue.request_rejected.isAccepted());
    try std.testing.expect(!CauseValue.session_context_not_found.isAccepted());
}
