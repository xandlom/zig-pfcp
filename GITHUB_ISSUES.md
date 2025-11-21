# GitHub Issues for zig-pfcp - User Feedback from PicoUP

Based on feedback from [PicoUP](https://github.com/xandlom/PicoUP/blob/main/docs/ZIG-PFCP-GAPS.md)

---

## Issue 1: Grouped IE Marshaling (CreatePDR, CreateFAR, CreateQER, CreateURR)

**Title:** Add marshaling support for grouped IEs (CreatePDR, CreateFAR, CreateQER, CreateURR)

**Labels:** `enhancement`, `priority-1`, `marshaling`

**Body:**

### Problem

The library has type definitions for grouped IEs (CreatePDR, CreateFAR, CreateQER, CreateURR) with builder patterns, but lacks encode/decode functions in `marshal.zig`. Users must manually encode these IEs as raw bytes.

### Current State

```zig
// In ie.zig - types exist with builders
pub const CreatePDR = struct {
    pdr_id: PDRID,
    precedence: Precedence,
    pdi: PDI,
    // ...
};

// In message.zig - stored as raw bytes
create_pdr: ?[]const u8 = null,  // Should be []CreatePDR
```

### Required Implementation

1. **Nested IE encoding** - Grouped IEs contain other IEs that must be recursively encoded
2. **Sub-component marshaling:**
   - PDI (Packet Detection Information)
   - ForwardingParameters
   - ApplyAction
   - OuterHeaderCreation
   - SDFFilter
   - SourceInterface, DestinationInterface
3. **Message integration** - Update SessionEstablishmentRequest/Response to use typed arrays

### Affected IEs

| IE Type | IE Type Code | Sub-IEs |
|---------|--------------|---------|
| CreatePDR | 1 | PDR ID, Precedence, PDI, FAR ID, URR ID, QER ID |
| CreateFAR | 3 | FAR ID, Apply Action, Forwarding Parameters |
| CreateURR | 6 | URR ID, Measurement Method, Reporting Triggers, Thresholds |
| CreateQER | 7 | QER ID, Gate Status, MBR, GBR, QFI |

### Reference

- 3GPP TS 29.244 Section 7.5.2 (Session Establishment)
- User feedback: https://github.com/xandlom/PicoUP/blob/main/docs/ZIG-PFCP-GAPS.md

---

## Issue 2: Implement SessionReportRequest/Response Messages

**Title:** Implement SessionReportRequest and SessionReportResponse messages

**Labels:** `enhancement`, `priority-1`, `message`

**Body:**

### Problem

SessionReportRequest and SessionReportResponse messages are completely missing from the library. These are essential for UPF to report usage metrics, events, and errors back to the SMF.

### Use Cases

- Report usage data when quota is exhausted
- Report downlink data arrival (buffering notification)
- Report error conditions
- Periodic usage reporting

### Required Implementation

1. **SessionReportRequest** (Message Type 56)
   - Report Type (mandatory)
   - Usage Report (conditional)
   - Error Indication Report (conditional)
   - Downlink Data Report (conditional)
   - Load Control Information (optional)
   - Overload Control Information (optional)

2. **SessionReportResponse** (Message Type 57)
   - Cause (mandatory)
   - Offending IE (conditional)
   - Update BAR (conditional)
   - SxSRRsp-Flags (optional)

### Message Type Codes

```zig
// In types.zig - need to add
session_report_request = 56,
session_report_response = 57,
```

### Reference

- 3GPP TS 29.244 Section 7.5.8 (Session Report)

---

## Issue 3: Implement Usage Reporting IEs

**Title:** Implement UsageReport, VolumeMeasurement, and DurationMeasurement IEs

**Labels:** `enhancement`, `priority-1`, `ie`

**Body:**

### Problem

Usage reporting IEs are not implemented, preventing UPF from reporting traffic measurements to SMF.

### Required IEs

| IE | Type Code | Purpose |
|----|-----------|---------|
| Usage Report (SRR) | 80 | Container for usage data in Session Report |
| Usage Report (SDR) | 81 | Container for usage data in Session Deletion Response |
| Usage Report (SMR) | 82 | Container for usage data in Session Modification Response |
| URR ID | 81 | Links report to rule |
| UR-SEQN | 104 | Usage report sequence number |
| Usage Report Trigger | 63 | What triggered the report |
| Volume Measurement | 66 | UL/DL/Total byte counts |
| Duration Measurement | 67 | Session duration in seconds |
| Time of First Packet | 69 | Timestamp |
| Time of Last Packet | 70 | Timestamp |
| Start Time | 75 | Measurement start |
| End Time | 76 | Measurement end |

### VolumeMeasurement Structure

```zig
pub const VolumeMeasurement = struct {
    flags: packed struct {
        tovol: bool,  // Total Volume present
        ulvol: bool,  // Uplink Volume present
        dlvol: bool,  // Downlink Volume present
        tonop: bool,  // Total Number of Packets present
        ulnop: bool,  // Uplink Number of Packets present
        dlnop: bool,  // Downlink Number of Packets present
    },
    total_volume: ?u64,
    uplink_volume: ?u64,
    downlink_volume: ?u64,
    total_packets: ?u64,
    uplink_packets: ?u64,
    downlink_packets: ?u64,
};
```

### Reference

- 3GPP TS 29.244 Section 8.2.40 (Volume Measurement)
- 3GPP TS 29.244 Section 8.2.41 (Duration Measurement)

---

## Issue 4: Implement Update/Remove IE Variants

**Title:** Implement Update and Remove variants for PDR, FAR, URR, QER, BAR

**Labels:** `enhancement`, `priority-2`, `ie`

**Body:**

### Problem

Session modification requires Update and Remove variants of rule IEs. Currently only Create variants exist.

### Required IEs

| Create (exists) | Update (missing) | Remove (missing) |
|-----------------|------------------|------------------|
| CreatePDR | UpdatePDR (IE Type 9) | RemovePDR (IE Type 15) |
| CreateFAR | UpdateFAR (IE Type 10) | RemoveFAR (IE Type 16) |
| CreateURR | UpdateURR (IE Type 13) | RemoveURR (IE Type 17) |
| CreateQER | UpdateQER (IE Type 14) | RemoveQER (IE Type 18) |
| CreateBAR | UpdateBAR (IE Type 12) | RemoveBAR (IE Type 87) |

### Update IE Structure

Update IEs are similar to Create IEs but all fields except ID are optional:

```zig
pub const UpdatePDR = struct {
    pdr_id: PDRID,              // mandatory - identifies rule to update
    precedence: ?Precedence,     // optional
    pdi: ?PDI,                   // optional
    far_id: ?FARID,             // optional
    // ...
};
```

### Remove IE Structure

Remove IEs only contain the ID:

```zig
pub const RemovePDR = struct {
    pdr_id: PDRID,
};
```

### Reference

- 3GPP TS 29.244 Section 7.5.4 (Session Modification)

---

## Issue 5: Complete SessionModification/Deletion Marshaling

**Title:** Complete marshaling for SessionModificationRequest/Response and SessionDeletionRequest/Response

**Labels:** `enhancement`, `priority-2`, `marshaling`

**Body:**

### Problem

SessionModificationRequest/Response and SessionDeletionRequest/Response have type definitions but incomplete or missing marshal functions.

### Current State

- Types defined in `message.zig`
- No `encodeSessionModificationRequest()` or `decodeSessionModificationRequest()` in `marshal.zig`
- No `encodeSessionDeletionRequest()` or `decodeSessionDeletionRequest()` in `marshal.zig`

### SessionModificationRequest Requirements

```zig
pub const SessionModificationRequest = struct {
    // Header fields
    cp_fseid: ?FSEID,

    // Rule modifications
    remove_pdr: ?[]RemovePDR,
    remove_far: ?[]RemoveFAR,
    remove_urr: ?[]RemoveURR,
    remove_qer: ?[]RemoveQER,

    create_pdr: ?[]CreatePDR,
    create_far: ?[]CreateFAR,
    create_urr: ?[]CreateURR,
    create_qer: ?[]CreateQER,

    update_pdr: ?[]UpdatePDR,
    update_far: ?[]UpdateFAR,
    update_urr: ?[]UpdateURR,
    update_qer: ?[]UpdateQER,

    // Query
    query_urr: ?[]URRID,
};
```

### SessionDeletionRequest/Response

Simpler structure - mainly header + cause for response.

### Depends On

- Issue #1 (Grouped IE Marshaling)
- Issue #4 (Update/Remove Variants)

### Reference

- 3GPP TS 29.244 Section 7.5.4 (Session Modification)
- 3GPP TS 29.244 Section 7.5.6 (Session Deletion)

---

## Issue 6: Complete 5G IE Marshaling (SNSSAI, QFI, etc.)

**Title:** Add marshaling support for 5G-specific IEs (SNSSAI, QFI, PDU Session Type)

**Labels:** `enhancement`, `priority-3`, `5g`, `marshaling`

**Body:**

### Problem

5G-specific IEs have type definitions but no marshaling functions. These are needed for proper 5G network slicing and QoS flow support.

### IEs with Types but No Marshaling

| IE | Type Code | Purpose |
|----|-----------|---------|
| SNSSAI | 148 | Network slice identifier (SST + SD) |
| QFI | 124 | QoS Flow Identifier |
| PDU Session Type | 113 | IPv4, IPv6, Ethernet, Unstructured |
| Ethernet PDU Session Information | 142 | Ethernet session indicator |
| MAC Address | 133 | Source/Destination MAC |
| C-TAG | 134 | Customer VLAN tag |
| S-TAG | 135 | Service VLAN tag |
| Ethertype | 136 | Ethernet frame type |

### SNSSAI Structure

```zig
pub const SNSSAI = struct {
    sst: u8,           // Slice/Service Type (mandatory)
    sd: ?[3]u8,        // Slice Differentiator (optional)
};
```

### Required Functions

```zig
// In marshal.zig
pub fn encodeSNSSAI(writer: *Writer, snssai: ie.SNSSAI) !void
pub fn decodeSNSSAI(reader: *Reader) !ie.SNSSAI
pub fn encodeQFI(writer: *Writer, qfi: ie.QFI) !void
pub fn decodeQFI(reader: *Reader) !ie.QFI
// ... etc
```

### Reference

- 3GPP TS 29.244 Section 8.2.101 (S-NSSAI)
- 3GPP TS 29.244 Section 8.2.89 (QFI)

---

## Summary

| Issue | Title | Priority | Depends On |
|-------|-------|----------|------------|
| 1 | Grouped IE Marshaling | P1 | - |
| 2 | SessionReportRequest/Response | P1 | #3 |
| 3 | Usage Reporting IEs | P1 | - |
| 4 | Update/Remove Variants | P2 | - |
| 5 | SessionModification/Deletion Marshaling | P2 | #1, #4 |
| 6 | 5G IE Marshaling | P3 | - |

**Estimated effort:** ~30% of original library implementation work.
