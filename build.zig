const std = @import("std");

fn register_day(b: *std.Build, target: *const std.Build.ResolvedTarget, optimize: *const std.builtin.OptimizeMode, all_tests: *std.Build.Step, comptime name: []const u8) void {
    const path = "src/" ++ name ++ ".zig";
    const artifact = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(path),
            .target = target.*,
            .optimize = optimize.*,
        }),
    });
    b.installArtifact(artifact);
    const run_step = b.step(name, "Run " ++ name);
    const run_one_cmd = b.addRunArtifact(artifact);
    run_step.dependOn(&run_one_cmd.step);
    run_one_cmd.step.dependOn(b.getInstallStep());
    const tests = b.addTest(.{
        .root_module = artifact.root_module,
    });

    const run_tests = b.addRunArtifact(tests);
    if (b.args) |args| {
        run_one_cmd
            .addArgs(args);
    }
    const run_tests_step = b.step(name ++ "-test", "Run tests for " ++ name);
    run_tests_step.dependOn(&run_tests.step);
    all_tests.*.dependOn(&run_tests.step);
}

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    // Standard target options allow the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    // It's also possible to define more custom flags to toggle optional features
    // of this build script using `b.option()`. All defined flags (including
    // target and optimize options) will be listed when running `zig build --help`
    // in this directory.

    // Here we define an executable. An executable needs to have a root module
    // which needs to expose a `main` function. While we could add a main function
    // to the module defined above, it's sometimes preferable to split business
    // logic and the CLI into two separate modules.
    //
    // If your goal is to create a Zig library for others to use, consider if
    // it might benefit from also exposing a CLI tool. A parser library for a
    // data serialization format could also bundle a CLI syntax checker, for example.
    //
    // If instead your goal is to create an executable, consider if users might
    // be interested in also being able to embed the core functionality of your
    // program in their own executable in order to avoid the overhead involved in
    // subprocessing your CLI tool.
    //
    // If neither case applies to you, feel free to delete the declaration you
    // don't need and to put everything under a single module.
    const test_step = b.step("test", "Run all tests");
    register_day(b, &target, &optimize, test_step, "one");
}
