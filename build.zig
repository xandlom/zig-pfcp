const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the main library
    const lib = b.addStaticLibrary(.{
        .name = "zig-pfcp",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    // Tests - comprehensive test suite
    const test_step = b.step("test", "Run all tests");

    // Add library tests
    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_lib_tests = b.addRunArtifact(lib_tests);
    test_step.dependOn(&run_lib_tests.step);

    // Add individual test files
    {
        const test_exe = b.addTest(.{
            .root_source_file = b.path("tests/types_test.zig"),
            .target = target,
            .optimize = optimize,
        });
        test_exe.root_module.addAnonymousImport("zig-pfcp", .{
            .root_source_file = b.path("src/lib.zig"),
        });
        const run_test = b.addRunArtifact(test_exe);
        test_step.dependOn(&run_test.step);
    }
    {
        const test_exe = b.addTest(.{
            .root_source_file = b.path("tests/ie_test.zig"),
            .target = target,
            .optimize = optimize,
        });
        test_exe.root_module.addAnonymousImport("zig-pfcp", .{
            .root_source_file = b.path("src/lib.zig"),
        });
        const run_test = b.addRunArtifact(test_exe);
        test_step.dependOn(&run_test.step);
    }
    {
        const test_exe = b.addTest(.{
            .root_source_file = b.path("tests/message_test.zig"),
            .target = target,
            .optimize = optimize,
        });
        test_exe.root_module.addAnonymousImport("zig-pfcp", .{
            .root_source_file = b.path("src/lib.zig"),
        });
        const run_test = b.addRunArtifact(test_exe);
        test_step.dependOn(&run_test.step);
    }
    {
        const test_exe = b.addTest(.{
            .root_source_file = b.path("tests/marshal_test.zig"),
            .target = target,
            .optimize = optimize,
        });
        test_exe.root_module.addAnonymousImport("zig-pfcp", .{
            .root_source_file = b.path("src/lib.zig"),
        });
        const run_test = b.addRunArtifact(test_exe);
        test_step.dependOn(&run_test.step);
    }
    {
        const test_exe = b.addTest(.{
            .root_source_file = b.path("tests/net_test.zig"),
            .target = target,
            .optimize = optimize,
        });
        test_exe.root_module.addAnonymousImport("zig-pfcp", .{
            .root_source_file = b.path("src/lib.zig"),
        });
        const run_test = b.addRunArtifact(test_exe);
        test_step.dependOn(&run_test.step);
    }

    // Benchmarks
    const benchmark_exe = b.addExecutable(.{
        .name = "marshal_bench",
        .root_source_file = b.path("benchmarks/marshal_bench.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });
    benchmark_exe.root_module.addAnonymousImport("zig-pfcp", .{
        .root_source_file = b.path("src/lib.zig"),
    });

    const install_bench = b.addInstallArtifact(benchmark_exe, .{});
    const bench_step = b.step("bench", "Build performance benchmarks");
    bench_step.dependOn(&install_bench.step);

    const run_bench = b.addRunArtifact(benchmark_exe);
    const run_bench_step = b.step("run-bench", "Run performance benchmarks");
    run_bench_step.dependOn(&run_bench.step);

    // Example binaries - session_client
    {
        const exe = b.addExecutable(.{
            .name = "session_client",
            .root_source_file = b.path("examples/session_client.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addAnonymousImport("zig-pfcp", .{
            .root_source_file = b.path("src/lib.zig"),
        });
        const install_exe = b.addInstallArtifact(exe, .{});
        const exe_step = b.step("session_client", "PFCP session client example");
        exe_step.dependOn(&install_exe.step);
        const run_exe = b.addRunArtifact(exe);
        if (b.args) |args| run_exe.addArgs(args);
        const run_step = b.step("run-session_client", "Run PFCP session client example");
        run_step.dependOn(&run_exe.step);
    }

    // Example binaries - session_server
    {
        const exe = b.addExecutable(.{
            .name = "session_server",
            .root_source_file = b.path("examples/session_server.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addAnonymousImport("zig-pfcp", .{
            .root_source_file = b.path("src/lib.zig"),
        });
        const install_exe = b.addInstallArtifact(exe, .{});
        const exe_step = b.step("session_server", "PFCP session server example");
        exe_step.dependOn(&install_exe.step);
        const run_exe = b.addRunArtifact(exe);
        if (b.args) |args| run_exe.addArgs(args);
        const run_step = b.step("run-session_server", "Run PFCP session server example");
        run_step.dependOn(&run_exe.step);
    }

    // Example binaries - message_builder
    {
        const exe = b.addExecutable(.{
            .name = "message_builder",
            .root_source_file = b.path("examples/message_builder.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addAnonymousImport("zig-pfcp", .{
            .root_source_file = b.path("src/lib.zig"),
        });
        const install_exe = b.addInstallArtifact(exe, .{});
        const exe_step = b.step("message_builder", "PFCP message builder example");
        exe_step.dependOn(&install_exe.step);
        const run_exe = b.addRunArtifact(exe);
        if (b.args) |args| run_exe.addArgs(args);
        const run_step = b.step("run-message_builder", "Run PFCP message builder example");
        run_step.dependOn(&run_exe.step);
    }

    // Production examples - smf_simulator
    {
        const exe = b.addExecutable(.{
            .name = "smf_simulator",
            .root_source_file = b.path("examples/production/smf_simulator.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addAnonymousImport("zig-pfcp", .{
            .root_source_file = b.path("src/lib.zig"),
        });
        const install_exe = b.addInstallArtifact(exe, .{});
        const exe_step = b.step("smf_simulator", "Production SMF simulator");
        exe_step.dependOn(&install_exe.step);
        const run_exe = b.addRunArtifact(exe);
        if (b.args) |args| run_exe.addArgs(args);
        const run_step = b.step("run-smf_simulator", "Run Production SMF simulator");
        run_step.dependOn(&run_exe.step);
    }

    // Production examples - upf_simulator
    {
        const exe = b.addExecutable(.{
            .name = "upf_simulator",
            .root_source_file = b.path("examples/production/upf_simulator.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addAnonymousImport("zig-pfcp", .{
            .root_source_file = b.path("src/lib.zig"),
        });
        const install_exe = b.addInstallArtifact(exe, .{});
        const exe_step = b.step("upf_simulator", "Production UPF simulator");
        exe_step.dependOn(&install_exe.step);
        const run_exe = b.addRunArtifact(exe);
        if (b.args) |args| run_exe.addArgs(args);
        const run_step = b.step("run-upf_simulator", "Run Production UPF simulator");
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
