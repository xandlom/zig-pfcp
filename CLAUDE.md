# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

**zig-pfcp** is a Zig implementation of the PFCP (Packet Forwarding Control Protocol) for 5G networks, following 3GPP TS 29.244 Release 18. It provides a comprehensive library for PFCP communication between Control Plane Functions (SMF) and User Plane Functions (UPF) in 5G networks.

## Build Commands

```bash
# Build the library
zig build

# Run tests (uses src/lib.zig as root)
zig build test

# Test individual modules
zig test src/types.zig
zig test src/ie.zig
zig test src/message.zig
zig test src/marshal.zig

# Build examples
zig build message_builder
zig build session_client
zig build session_server

# Run examples
zig build run-message_builder
zig build run-session_client
zig build run-session_server

# Generate documentation
zig build docs
```

**Zig Version**: Requires 0.15.2

## Architecture

### Module Structure

The codebase is organized into layered modules that mirror the PFCP protocol stack:

**Core Protocol Layer** (`types.zig`)
- Defines fundamental PFCP constants (PFCP_VERSION, PFCP_PORT)
- `PfcpHeader`: Header structure with version, flags, SEID, sequence number
- `MessageType`: Enum of 25+ message types (Node messages 1-15, Session messages 50-99)
- `IEType`: Enum of 139+ Information Element types
- `CauseValue`: Request acceptance/rejection codes
- Helper functions like `MessageType.hasSession()` to distinguish node vs session messages

**Information Elements Layer** (`ie.zig`)
- Implements 139+ Information Elements (IEs) per 3GPP TS 29.244 Section 8.2
- Each IE has an `IEHeader` (type + length)
- Core IEs:
  - `RecoveryTimeStamp`: NTP-based timestamps for tracking node restarts
  - `NodeId`: Node identification (IPv4, IPv6, or FQDN variants)
  - `FSEID`: Session endpoint identifier with SEID + IP address
  - `FTEID`: Tunnel endpoint identifier with TEID + IP, supports CHOOSE flag for UPF allocation
  - `UEIPAddress`: User equipment IP addressing with SD and CHOOSE flags
  - `Cause`: Request acceptance/rejection with detailed error codes
- Advanced IEs:
  - `PDR`: Packet Detection Rules (traffic filtering)
  - `FAR`: Forwarding Action Rules (traffic handling: drop, forward, buffer)
  - `QER`: QoS Enforcement Rules (rate limiting, marking)
  - `URR`: Usage Reporting Rules (quota management, measurement)
- All IEs use builder patterns with type-safe constructors (e.g., `FSEID.initV4()`, `FTEID.initChoose()`)

**Message Layer** (`message.zig`)
- Implements 25+ PFCP message types per 3GPP TS 29.244 Section 7.4
- Node messages: `HeartbeatRequest/Response`, `AssociationSetupRequest/Response`, `AssociationUpdateRequest/Response`, `AssociationReleaseRequest/Response`, `PFDManagementRequest/Response`, `NodeReportRequest/Response`, `SessionSetDeletionRequest/Response`
- Session messages: `SessionEstablishmentRequest/Response`, `SessionModificationRequest/Response`, `SessionDeletionRequest/Response`, `SessionReportRequest/Response`
- Each message type has:
  - `init()`: Basic constructor
  - Convenience constructors like `accepted()` for responses
- Messages compose IEs from the IE layer

**Marshaling Layer** (`marshal.zig`)
- Binary encoding/decoding to PFCP wire format
- `Writer`: Encodes PFCP structures to binary (big-endian network byte order)
  - Methods: `writeByte()`, `writeU16()`, `writeU24()`, `writeU32()`, `writeU64()`, `writeBytes()`
  - Tracks buffer position and validates space
- `Reader`: Decodes binary to PFCP structures
  - Corresponding read methods for each data type
  - Validates length constraints
- Handles variable-length IEs, grouped IEs, and proper endianness conversion
- All marshaling uses big-endian format per protocol spec

**Network Layer** (`net.zig`)
- UDP socket communication on port 8805
- `SequenceManager`: Thread-safe sequence number generation (24-bit wraparound)
- `PendingRequest`: Tracks outstanding requests for retransmission
- `PfcpSocket`: UDP socket wrapper with send/receive operations
- `PfcpConnection`: Connection-oriented abstraction with retransmission handling
- Constants:
  - `MAX_MESSAGE_SIZE`: 8192 bytes (MTU-based)
  - `DEFAULT_TIMEOUT_MS`: 5000ms
  - `MAX_RETRANSMISSIONS`: 3 attempts

**Utilities** (`util.zig`)
- Helper functions for common operations
- IP address parsing and validation
- Time conversion utilities (Unix time ↔ NTP time)

### Key Design Patterns

1. **Type Safety**: Extensive use of Zig's type system with packed structs for bit flags, enums for protocol constants, and tagged unions for polymorphic IEs

2. **Builder Pattern**: All messages and IEs use builder-style constructors:
   ```zig
   const fseid = pfcp.ie.FSEID.initV4(seid, [_]u8{10, 0, 0, 1});
   const session_req = pfcp.SessionEstablishmentRequest.init(node_id, fseid);
   ```

3. **Convenience Methods**: Response messages have helper constructors:
   ```zig
   const response = pfcp.AssociationSetupResponse.accepted(node_id, recovery);
   ```

4. **Zero Dependencies**: Pure Zig implementation using only the standard library

5. **Layered Architecture**: Each layer (types → IEs → messages → marshaling → network) builds on the previous, mirroring the protocol stack

6. **CHOOSE Flag Pattern**: F-TEID supports letting the UPF allocate TEIDs/IPs:
   ```zig
   const fteid = pfcp.ie.FTEID.initChoose(); // UPF decides
   const fteid_v4 = pfcp.ie.FTEID.initV4(0x12345678, [_]u8{10, 0, 0, 1}); // Explicit
   ```

### 3GPP Specification Compliance

- Follows 3GPP TS 29.244 Release 18 specification
- Section references included in comments throughout codebase
- All message types from Node (1-15) and Session (50-99) ranges
- Full IE support including 5G-specific features (Network Slicing, S-NSSAI, QoS flows)
- Proper handling of mandatory vs optional IEs
- Binary format exactly matches wire protocol (big-endian, proper length calculations)

### Testing Strategy

Tests are embedded within source files using Zig's `test` blocks. The main test entry point is `src/lib.zig`, which references all module tests via `std.testing.refAllDecls(@This())`. Run `zig build test` to execute all tests across modules.

### Development Phases

The project was built in phases (see git history):
- Phase 1: Core protocol (messages, IEs, types)
- Phase 2: Binary serialization (marshal/unmarshal)
- Phase 3: Advanced IEs (PDR, FAR, QER, URR)
- Phase 4: Network layer (UDP, sequence management)
- Phase 5: Advanced 5G features (completed)
- Phase 6: Production readiness (in progress)

When adding new message types or IEs, follow the established pattern in existing implementations and add corresponding tests.
