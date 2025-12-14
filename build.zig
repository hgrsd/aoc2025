const std = @import("std");

fn registerDay(b: *std.Build, target: *const std.Build.ResolvedTarget, optimize: *const std.builtin.OptimizeMode, allTests: *std.Build.Step, comptime name: []const u8) void {
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
    const runArtifact = b.addRunArtifact(executable);
    runArtifact.step.dependOn(b.getInstallStep());
    const runStep = b.step(name, "Run " ++ name);
    runStep.dependOn(&runArtifact.step);

    // tests
    const tests = b.addTest(.{
        .root_module = executable.root_module,
    });
    const testArtifact = b.addRunArtifact(tests);
    const runTestsStep = b.step(name ++ "-test", "Run tests for " ++ name);
    runTestsStep.dependOn(&testArtifact.step);
    allTests.*.dependOn(&testArtifact.step);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const allTests = b.step("test", "Run all tests");
    registerDay(b, &target, &optimize, allTests, "one");
    registerDay(b, &target, &optimize, allTests, "two");
    registerDay(b, &target, &optimize, allTests, "three");
    registerDay(b, &target, &optimize, allTests, "four");
    registerDay(b, &target, &optimize, allTests, "five");
}
