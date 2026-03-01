const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create root module for main executable
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Main executable
    const exe = b.addExecutable(.{
        .name = "zigsysmon",
        .root_module = root_module,
    });

    b.installArtifact(exe);

    // Run step
    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the system monitor");
    run_step.dependOn(&run_cmd.step);

    // Create module for tests
    const test_module = b.createModule(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Test executable
    const test_exe = b.addTest(.{
        .root_module = test_module,
    });

    const test_run = b.addRunArtifact(test_exe);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&test_run.step);

    // Check step (build without optimization for faster iteration)
    const check_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .Debug,
    });

    const check = b.addExecutable(.{
        .name = "check",
        .root_module = check_module,
    });
    const check_step = b.step("check", "Check if code compiles");
    check_step.dependOn(&check.step);
}
