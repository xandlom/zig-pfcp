// PCAP File Format Reader/Writer for PFCP Traffic
// Implements libpcap file format for capturing and replaying PFCP messages
// Reference: https://wiki.wireshark.org/Development/LibpcapFileFormat

const std = @import("std");
const net = std.net;

/// PCAP File Header (24 bytes)
pub const PcapFileHeader = packed struct {
    magic_number: u32, // 0xa1b2c3d4
    version_major: u16, // 2
    version_minor: u16, // 4
    thiszone: i32, // GMT to local correction
    sigfigs: u32, // accuracy of timestamps
    snaplen: u32, // max length of captured packets
    network: u32, // data link type (1 = Ethernet)

    pub fn init() PcapFileHeader {
        return .{
            .magic_number = 0xa1b2c3d4,
            .version_major = 2,
            .version_minor = 4,
            .thiszone = 0,
            .sigfigs = 0,
            .snaplen = 65535,
            .network = 1, // DLT_EN10MB (Ethernet)
        };
    }
};

/// PCAP Packet Header (16 bytes)
pub const PcapPacketHeader = packed struct {
    ts_sec: u32, // timestamp seconds
    ts_usec: u32, // timestamp microseconds
    incl_len: u32, // number of octets of packet saved
    orig_len: u32, // actual length of packet

    pub fn init(timestamp: i64, length: u32) PcapPacketHeader {
        const sec: u32 = @intCast(@divFloor(timestamp, 1_000_000));
        const usec: u32 = @intCast(@mod(timestamp, 1_000_000));

        return .{
            .ts_sec = sec,
            .ts_usec = usec,
            .incl_len = length,
            .orig_len = length,
        };
    }
};

/// Ethernet Header (14 bytes)
pub const EthernetHeader = packed struct {
    dst_mac: [6]u8, // destination MAC address
    src_mac: [6]u8, // source MAC address
    ethertype: u16, // 0x0800 for IPv4

    pub fn init() EthernetHeader {
        return .{
            .dst_mac = [_]u8{0} ** 6,
            .src_mac = [_]u8{0} ** 6,
            .ethertype = 0x0800, // IPv4
        };
    }
};

/// IPv4 Header (20 bytes, simplified without options)
pub const Ipv4Header = packed struct {
    version_ihl: u8, // version (4 bits) + IHL (4 bits)
    dscp_ecn: u8, // DSCP (6 bits) + ECN (2 bits)
    total_length: u16,
    identification: u16,
    flags_fragment: u16,
    ttl: u8,
    protocol: u8, // 17 for UDP
    checksum: u16,
    src_addr: [4]u8,
    dst_addr: [4]u8,

    pub fn init(src: [4]u8, dst: [4]u8, udp_length: u16) Ipv4Header {
        return .{
            .version_ihl = 0x45, // IPv4, IHL=5 (20 bytes)
            .dscp_ecn = 0,
            .total_length = 20 + udp_length,
            .identification = 0,
            .flags_fragment = 0,
            .ttl = 64,
            .protocol = 17, // UDP
            .checksum = 0, // Can be 0 for now
            .src_addr = src,
            .dst_addr = dst,
        };
    }
};

/// UDP Header (8 bytes)
pub const UdpHeader = packed struct {
    src_port: u16,
    dst_port: u16,
    length: u16,
    checksum: u16,

    pub fn init(src_port: u16, dst_port: u16, payload_length: u16) UdpHeader {
        return .{
            .src_port = src_port,
            .dst_port = dst_port,
            .length = 8 + payload_length,
            .checksum = 0, // Can be 0 for UDP
        };
    }
};

/// PCAP Writer
pub const PcapWriter = struct {
    file: std.fs.File,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, path: []const u8) !PcapWriter {
        const file = try std.fs.cwd().createFile(path, .{});

        var writer = PcapWriter{
            .file = file,
            .allocator = allocator,
        };

        // Write PCAP file header
        try writer.writeFileHeader();

        return writer;
    }

    pub fn deinit(self: *PcapWriter) void {
        self.file.close();
    }

    fn writeFileHeader(self: *PcapWriter) !void {
        const header = PcapFileHeader.init();
        const bytes = std.mem.asBytes(&header);
        try self.file.writeAll(bytes);
    }

    pub fn writePacket(
        self: *PcapWriter,
        src_addr: [4]u8,
        dst_addr: [4]u8,
        src_port: u16,
        dst_port: u16,
        payload: []const u8,
        timestamp: i64,
    ) !void {
        const eth_size = @sizeOf(EthernetHeader);
        const ip_size = @sizeOf(Ipv4Header);
        const udp_size = @sizeOf(UdpHeader);
        const total_size = eth_size + ip_size + udp_size + payload.len;

        // Build packet
        var packet_buffer = try self.allocator.alloc(u8, total_size);
        defer self.allocator.free(packet_buffer);

        var pos: usize = 0;

        // Ethernet header
        const eth = EthernetHeader.init();
        @memcpy(packet_buffer[pos..][0..eth_size], std.mem.asBytes(&eth));
        pos += eth_size;

        // IPv4 header
        const ipv4 = Ipv4Header.init(src_addr, dst_addr, @intCast(udp_size + payload.len));
        @memcpy(packet_buffer[pos..][0..ip_size], std.mem.asBytes(&ipv4));
        pos += ip_size;

        // UDP header
        const udp = UdpHeader.init(
            std.mem.nativeToBig(u16, src_port),
            std.mem.nativeToBig(u16, dst_port),
            @intCast(payload.len),
        );
        @memcpy(packet_buffer[pos..][0..udp_size], std.mem.asBytes(&udp));
        pos += udp_size;

        // Payload
        @memcpy(packet_buffer[pos..][0..payload.len], payload);

        // Write packet header
        const pkt_header = PcapPacketHeader.init(timestamp, @intCast(total_size));
        try self.file.writeAll(std.mem.asBytes(&pkt_header));

        // Write packet data
        try self.file.writeAll(packet_buffer);
    }
};

/// PCAP Reader
pub const PcapReader = struct {
    file: std.fs.File,
    allocator: std.mem.Allocator,
    file_header: PcapFileHeader,

    pub fn init(allocator: std.mem.Allocator, path: []const u8) !PcapReader {
        const file = try std.fs.cwd().openFile(path, .{});

        // Read file header
        var header_buf: [@sizeOf(PcapFileHeader)]u8 = undefined;
        _ = try file.readAll(&header_buf);

        const file_header = std.mem.bytesAsValue(PcapFileHeader, &header_buf).*;

        // Verify magic number
        if (file_header.magic_number != 0xa1b2c3d4 and file_header.magic_number != 0xd4c3b2a1) {
            return error.InvalidPcapFile;
        }

        return PcapReader{
            .file = file,
            .allocator = allocator,
            .file_header = file_header,
        };
    }

    pub fn deinit(self: *PcapReader) void {
        self.file.close();
    }

    pub const Packet = struct {
        timestamp: i64,
        src_addr: [4]u8,
        dst_addr: [4]u8,
        src_port: u16,
        dst_port: u16,
        payload: []u8,
        allocator: std.mem.Allocator,

        pub fn deinit(self: *Packet) void {
            self.allocator.free(self.payload);
        }
    };

    pub fn readPacket(self: *PcapReader) !?Packet {
        // Read packet header
        var pkt_header_buf: [@sizeOf(PcapPacketHeader)]u8 = undefined;
        const bytes_read = self.file.read(&pkt_header_buf) catch |err| {
            if (err == error.EndOfStream) return null;
            return err;
        };

        if (bytes_read == 0) return null;
        if (bytes_read < @sizeOf(PcapPacketHeader)) return error.TruncatedPacket;

        const pkt_header = std.mem.bytesAsValue(PcapPacketHeader, &pkt_header_buf).*;

        // Read packet data
        const packet_data = try self.allocator.alloc(u8, pkt_header.incl_len);
        errdefer self.allocator.free(packet_data);

        const data_read = try self.file.readAll(packet_data);
        if (data_read != pkt_header.incl_len) return error.TruncatedPacket;

        // Parse Ethernet header (14 bytes)
        if (packet_data.len < 14) return error.TruncatedPacket;
        var pos: usize = 14;

        // Parse IPv4 header (20 bytes minimum)
        if (packet_data.len < pos + 20) return error.TruncatedPacket;

        const src_addr = packet_data[pos + 12 ..][0..4].*;
        const dst_addr = packet_data[pos + 16 ..][0..4].*;
        pos += 20;

        // Parse UDP header (8 bytes)
        if (packet_data.len < pos + 8) return error.TruncatedPacket;

        const src_port = std.mem.readInt(u16, packet_data[pos..][0..2], .big);
        const dst_port = std.mem.readInt(u16, packet_data[pos + 2 ..][0..2], .big);
        pos += 8;

        // Extract payload
        const payload = try self.allocator.alloc(u8, packet_data.len - pos);
        @memcpy(payload, packet_data[pos..]);

        self.allocator.free(packet_data);

        const timestamp: i64 = @as(i64, pkt_header.ts_sec) * 1_000_000 + @as(i64, pkt_header.ts_usec);

        return Packet{
            .timestamp = timestamp,
            .src_addr = src_addr,
            .dst_addr = dst_addr,
            .src_port = src_port,
            .dst_port = dst_port,
            .payload = payload,
            .allocator = self.allocator,
        };
    }
};

test "PcapFileHeader - initialization" {
    const header = PcapFileHeader.init();

    try std.testing.expectEqual(@as(u32, 0xa1b2c3d4), header.magic_number);
    try std.testing.expectEqual(@as(u16, 2), header.version_major);
    try std.testing.expectEqual(@as(u16, 4), header.version_minor);
    try std.testing.expectEqual(@as(u32, 65535), header.snaplen);
}

test "PcapPacketHeader - initialization" {
    const timestamp: i64 = 1234567890123456;
    const header = PcapPacketHeader.init(timestamp, 100);

    try std.testing.expectEqual(@as(u32, 1234567), header.ts_sec);
    try std.testing.expectEqual(@as(u32, 890123456), header.ts_usec);
    try std.testing.expectEqual(@as(u32, 100), header.incl_len);
}

test "EthernetHeader - initialization" {
    const eth = EthernetHeader.init();

    try std.testing.expectEqual(@as(u16, 0x0800), eth.ethertype);
}

test "Ipv4Header - initialization" {
    const src = [_]u8{ 192, 168, 1, 1 };
    const dst = [_]u8{ 192, 168, 1, 2 };
    const ip = Ipv4Header.init(src, dst, 100);

    try std.testing.expectEqual(@as(u8, 0x45), ip.version_ihl);
    try std.testing.expectEqual(@as(u8, 17), ip.protocol); // UDP
    try std.testing.expectEqual(src, ip.src_addr);
    try std.testing.expectEqual(dst, ip.dst_addr);
}

test "UdpHeader - initialization" {
    const udp = UdpHeader.init(8805, 8805, 100);

    try std.testing.expectEqual(@as(u16, 108), udp.length); // 8 + 100
}
