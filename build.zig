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
    const test_files = [_][]const u8{
        "tests/types_test.zig",
        "tests/ie_test.zig",
        "tests/message_test.zig",
        "tests/marshal_test.zig",
        "tests/net_test.zig",
    };

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
    inline for (test_files) |test_file| {
        const test_exe = b.addTest(.{
            .root_source_file = b.path(test_file),
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

    // Example binaries
    const examples = [_]struct {
        name: []const u8,
        description: []const u8,
    }{
        .{ .name = "session_client", .description = "PFCP session client example" },
        .{ .name = "session_server", .description = "PFCP session server example" },
        .{ .name = "message_builder", .description = "PFCP message builder example" },
    };

    // Production examples
    const production_examples = [_]struct {
        name: []const u8,
        path: []const u8,
        description: []const u8,
    }{
        .{ .name = "smf_simulator", .path = "examples/production/smf_simulator.zig", .description = "Production SMF simulator" },
        .{ .name = "upf_simulator", .path = "examples/production/upf_simulator.zig", .description = "Production UPF simulator" },
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
        exe.root_module.addAnonymousImport("zig-pfcp", .{
            .root_source_file = b.path("src/lib.zig"),
        });

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

    // Production examples
    inline for (production_examples) |prod_example| {
        const exe = b.addExecutable(.{
            .name = prod_example.name,
            .root_source_file = b.path(prod_example.path),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addAnonymousImport("zig-pfcp", .{
            .root_source_file = b.path("src/lib.zig"),
        });

        const install_exe = b.addInstallArtifact(exe, .{});

        const exe_step = b.step(
            prod_example.name,
            prod_example.description,
        );
        exe_step.dependOn(&install_exe.step);

        const run_exe = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_exe.addArgs(args);
        }

        const run_step = b.step(
            b.fmt("run-{s}", .{prod_example.name}),
            b.fmt("Run {s}", .{prod_example.description}),
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
