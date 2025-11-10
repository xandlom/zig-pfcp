# zig-pfcp

A Zig implementation of the PFCP (Packet Forwarding Control Protocol) for 5G networks, based on 3GPP TS 29.244 Release 18 specification.

## Overview

**zig-pfcp** is a comprehensive library for implementing PFCP protocol communication between the Control Plane Function (SMF) and User Plane Function (UPF) in 5G networks. This implementation aims to provide the same level of compliance and features as the reference [rs-pfcp](https://github.com/xandlom/rs-pfcp) Rust implementation.

### Features

- 🎯 **Full Protocol Support**: Implementation of 25+ PFCP message types
- 📦 **Rich IE Library**: 139+ Information Elements with proper type safety
- 🔧 **Builder Patterns**: Ergonomic APIs for constructing messages
- ✅ **Comprehensive Testing**: Unit tests for all core components
- 🚀 **Zero Dependencies**: Pure Zig implementation
- 📚 **Well Documented**: Full API documentation with examples

### Supported Message Types

#### Node Messages (1-15)
- Heartbeat Request/Response
- Association Setup/Update/Release Request/Response
- PFD Management Request/Response
- Node Report Request/Response
- Session Set Deletion Request/Response

#### Session Messages (50-99)
- Session Establishment Request/Response
- Session Modification Request/Response
- Session Deletion Request/Response
- Session Report Request/Response

### Key Information Elements

- **F-SEID**: Session Endpoint Identifier with IPv4/IPv6 support
- **F-TEID**: Tunnel Endpoint Identifier with CHOOSE flag support
- **Node ID**: IPv4, IPv6, and FQDN node identification
- **UE IP Address**: User Equipment IP addressing
- **PDR/FAR/QER/URR IDs**: Packet Detection, Forwarding, QoS, and Usage Reporting Rules
- **Cause**: Request acceptance/rejection with detailed error codes
- **Apply Action**: Traffic handling actions (drop, forward, buffer, etc.)

## Requirements

- **Zig 0.15.2** or later

## Installation

### Using as a Library

Add this to your `build.zig.zon`:

```zig
.dependencies = .{
    .zig_pfcp = .{
        .url = "https://github.com/xandlom/zig-pfcp/archive/<commit-hash>.tar.gz",
        .hash = "<hash>",
    },
},
```

Then in your `build.zig`:

```zig
const pfcp = b.dependency("zig_pfcp", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("zig-pfcp", pfcp.module("zig-pfcp"));
```

### Building from Source

```bash
# Clone the repository
git clone https://github.com/xandlom/zig-pfcp.git
cd zig-pfcp

# Build the library
zig build

# Run tests
zig build test

# Build examples
zig build message_builder
zig build session_client
zig build session_server

# Generate documentation
zig build docs
```

## Quick Start

### Basic Message Construction

```zig
const std = @import("std");
const pfcp = @import("zig-pfcp");

pub fn main() !void {
    // Create a Heartbeat Request
    const recovery = pfcp.ie.RecoveryTimeStamp.fromUnixTime(std.time.timestamp());
    const heartbeat = pfcp.HeartbeatRequest.init(recovery);

    // Create an Association Setup Request
    const node_id = pfcp.ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
    const assoc_req = pfcp.AssociationSetupRequest.init(node_id, recovery);

    // Create a Session Establishment Request
    const seid: u64 = 0x1234567890ABCDEF;
    const fseid = pfcp.ie.FSEID.initV4(seid, [_]u8{ 10, 0, 0, 1 });
    const session_req = pfcp.SessionEstablishmentRequest.init(node_id, fseid);
}
```

### Response with Convenience Methods

```zig
// Accept an Association Setup
const response = pfcp.AssociationSetupResponse.accepted(node_id, recovery);

// Accept a Session Establishment
const up_seid: u64 = 0xFEDCBA0987654321;
const up_fseid = pfcp.ie.FSEID.initV4(up_seid, [_]u8{ 10, 0, 0, 2 });
const session_resp = pfcp.SessionEstablishmentResponse.accepted(node_id, up_fseid);
```

### F-TEID with CHOOSE Flag

```zig
// Let UPF choose the TEID and IP address
const fteid = pfcp.ie.FTEID.initChoose();

// Or specify explicitly
const fteid_v4 = pfcp.ie.FTEID.initV4(0x12345678, [_]u8{ 10, 0, 0, 1 });
```

## Project Structure

```
zig-pfcp/
├── build.zig              # Build configuration
├── build.zig.zon          # Package manifest
├── src/
│   ├── lib.zig           # Main library entry point
│   ├── types.zig         # Core PFCP types and enums
│   ├── ie.zig            # Information Elements
│   ├── message.zig       # Message types
│   └── util.zig          # Utility functions
├── examples/
│   ├── message_builder.zig   # Message construction examples
│   ├── session_client.zig    # Client-side example
│   └── session_server.zig    # Server-side example
├── tests/                # Test files
└── README.md
```

## Running Examples

```bash
# Build and run the message builder example
zig build run-message_builder

# Build and run the session client example
zig build run-session_client

# Build and run the session server example
zig build run-session_server

# Build and run production examples
zig build run-smf_simulator
zig build run-upf_simulator
```

## Production Features

### Comprehensive Testing

The library includes extensive test coverage across all modules:

```bash
# Run all tests (includes unit tests for all modules)
zig build test
```

Test files:
- `tests/types_test.zig` - Core types and enums
- `tests/ie_test.zig` - Information Elements
- `tests/message_test.zig` - PFCP messages
- `tests/marshal_test.zig` - Binary encoding/decoding
- `tests/net_test.zig` - Network layer

### Performance Benchmarks

Measure the performance of critical operations:

```bash
# Build and run benchmarks
zig build run-bench
```

Benchmarks include:
- Marshal/unmarshal operations (Writer/Reader)
- Message encoding/decoding
- Round-trip performance

### Message Comparison Framework

Utility functions for comparing PFCP messages and IEs:

```zig
const pfcp = @import("zig-pfcp");

// Compare Node IDs
const node1 = pfcp.ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
const node2 = pfcp.ie.NodeId.initIpv4([_]u8{ 192, 168, 1, 1 });
const result = pfcp.compare.compareNodeId(node1, node2);
// result == .equal

// Compare F-SEIDs
const fseid1 = pfcp.ie.FSEID.initV4(0x1234, [_]u8{ 10, 0, 0, 1 });
const fseid2 = pfcp.ie.FSEID.initV4(0x1234, [_]u8{ 10, 0, 0, 1 });
const equal = pfcp.compare.compareFSEID(fseid1, fseid2);
```

### PCAP Support

Read and write PFCP traffic in PCAP format for analysis:

```zig
const pfcp = @import("zig-pfcp");

// Write PFCP traffic to PCAP file
var writer = try pfcp.pcap.PcapWriter.init(allocator, "capture.pcap");
defer writer.deinit();

try writer.writePacket(
    [_]u8{ 192, 168, 1, 1 },  // src IP
    [_]u8{ 192, 168, 1, 2 },  // dst IP
    8805,                      // src port
    8805,                      // dst port
    payload,                   // PFCP message data
    std.time.microTimestamp(),
);

// Read PFCP traffic from PCAP file
var reader = try pfcp.pcap.PcapReader.init(allocator, "capture.pcap");
defer reader.deinit();

while (try reader.readPacket()) |packet| {
    defer packet.deinit();
    // Process packet.payload
}
```

### Production Simulators

Two production-ready examples demonstrate complete SMF and UPF implementations:

- **SMF Simulator** (`examples/production/smf_simulator.zig`)
  - Association management
  - Session lifecycle (create, modify, delete)
  - Heartbeat mechanism
  - Demonstrates Control Plane operations

- **UPF Simulator** (`examples/production/upf_simulator.zig`)
  - Association handling
  - Session state management
  - Response generation
  - Demonstrates User Plane operations

## Development Roadmap

### Phase 1: Core Protocol (Current)
- [x] Basic message types (Heartbeat, Association Setup/Release)
- [x] Session messages (Establishment, Modification, Deletion)
- [x] Core Information Elements (Node ID, F-SEID, F-TEID, Cause)
- [x] Type-safe enums and structures
- [x] Build system and project structure

### Phase 2: Binary Serialization
- [x] Message marshaling (encoding to binary)
- [x] Message unmarshaling (decoding from binary)
- [x] Proper handling of variable-length IEs
- [x] Endianness handling
- [x] Length field calculations

### Phase 3: Advanced IEs
- [x] PDR (Packet Detection Rule) IE
- [x] FAR (Forwarding Action Rule) IE
- [x] QER (QoS Enforcement Rule) IE
- [x] URR (Usage Reporting Rule) IE
- [x] Grouped IEs support
- [x] Extended IE handling

### Phase 4: Network Layer
- [x] UDP socket implementation
- [x] Message send/receive
- [x] Sequence number management
- [x] Retransmission handling
- [x] Connection management

### Phase 5: Advanced Features
- [x] 5G-specific features (Network Slicing, S-NSSAI)
- [x] QoS flow handling
- [x] Usage reporting and quotas
- [x] Multi-access support
- [x] Ethernet PDU session support

### Phase 6: Production Readiness
- [x] Comprehensive test coverage
- [x] Performance benchmarks
- [x] Message comparison framework
- [x] PCAP reader/writer
- [x] Production examples (SMF/UPF simulators)

## Testing

```bash
# Run all tests
zig build test

# Run specific test
zig test src/types.zig
zig test src/ie.zig
zig test src/message.zig
```

## Documentation

Generate and view the API documentation:

```bash
# Generate documentation
zig build docs

# Documentation will be in zig-out/docs/
```

## Contributing

Contributions are welcome! Please ensure:

1. All tests pass: `zig build test`
2. Code follows Zig style guidelines
3. New features include tests and documentation
4. Commit messages are clear and descriptive

## Protocol Reference

- **3GPP TS 29.244**: PFCP (Packet Forwarding Control Protocol)
- **Release 18**: Latest specification with 5G enhancements

## Related Projects

- [rs-pfcp](https://github.com/xandlom/rs-pfcp) - Reference Rust implementation
- [free5GC](https://github.com/free5gc/free5gc) - Open-source 5G core network
- [open5gs](https://github.com/open5gs/open5gs) - Open-source 5G/4G core network

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Based on the excellent [rs-pfcp](https://github.com/xandlom/rs-pfcp) implementation
- 3GPP for the PFCP specification
- The Zig community for the amazing language and tools

## Contact

For questions, issues, or contributions, please open an issue on GitHub.

---

**Status**: ✅ Production Ready - All phases complete! Comprehensive PFCP implementation with full test coverage, performance benchmarks, PCAP support, and production examples.
