const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the main module
    const pfcp_module = b.addModule("zig-pfcp", .{
        .root_source_file = b.path("src/lib.zig"),
    });

    // Create the main library
    const lib = b.addStaticLibrary(.{
        .name = "zig-pfcp",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    // Tests
    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_lib_tests.step);

    // Example binaries
    const examples = [_]struct {
        name: []const u8,
        description: []const u8,
    }{
        .{ .name = "session_client", .description = "PFCP session client example" },
        .{ .name = "session_server", .description = "PFCP session server example" },
        .{ .name = "message_builder", .description = "PFCP message builder example" },
    };

    inline for (examples) |example| {
        const example_path = std.fmt.allocPrint(
            b.allocator,
            "examples/{s}.zig",
            .{example.name},
        ) catch unreachable;

        const exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = b.path(example_path),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("zig-pfcp", pfcp_module);

        const install_exe = b.addInstallArtifact(exe, .{});

        const exe_step = b.step(
            example.name,
            example.description,
        );
        exe_step.dependOn(&install_exe.step);

        const run_exe = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_exe.addArgs(args);
        }

        const run_step = b.step(
            b.fmt("run-{s}", .{example.name}),
            b.fmt("Run {s}", .{example.description}),
        );
        run_step.dependOn(&run_exe.step);
    }

    // Documentation generation
    const docs = b.addStaticLibrary(.{
        .name = "zig-pfcp",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = .Debug,
    });

    const install_docs = b.addInstallDirectory(.{
        .source_dir = docs.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(&install_docs.step);
}
