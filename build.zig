const std = @import("std");

fn register_day(b: *std.Build, target: *const std.Build.ResolvedTarget, optimize: *const std.builtin.OptimizeMode, all_tests: *std.Build.Step, comptime name: []const u8) void {
    const path = "src/" ++ name ++ ".zig";

    // executable
    const executable = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(path),
            .target = target.*,
            .optimize = optimize.*,
        }),
    });
    b.installArtifact(executable);
    const run_artifact = b.addRunArtifact(executable);
    run_artifact.step.dependOn(b.getInstallStep());
    const run_step = b.step(name, "Run " ++ name);
    run_step.dependOn(&run_artifact.step);

    // tests
    const tests = b.addTest(.{
        .root_module = executable.root_module,
    });
    const test_artifact = b.addRunArtifact(tests);
    const run_tests_step = b.step(name ++ "-test", "Run tests for " ++ name);
    run_tests_step.dependOn(&test_artifact.step);
    all_tests.*.dependOn(&test_artifact.step);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const all_tests = b.step("test", "Run all tests");
    register_day(b, &target, &optimize, all_tests, "one");
}
