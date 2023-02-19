const std = @import("std");
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // Executable configuration
    {
        const exe = b.addExecutable("zmenu", "src/main.zig");
        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        configureStep(exe, target, mode);

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);

        exe.linkSystemLibrary("c");
    }

    // Testing configuration
    {
        const test_roots = &[_][]const u8{
            "src/main.zig",
        };

        const test_step = b.step("test", "Test the app");

        for (test_roots) |test_root| {
            const test_ = b.addTest(test_root);
            configureStep(test_, target, mode);
            test_step.dependOn(&test_.step);
        }
    }
}

fn configureStep(
    step: *std.build.LibExeObjStep,
    target: anytype, // FIXME: how do I describe this type
    mode: std.builtin.Mode,
) void {
    step.setTarget(target);
    step.setBuildMode(mode);

    inline for (&[_]i32{
        // Pkg{ .name = "poly", .path = "../zig-poly/src/poly.zig" },
    }) |*pkg| {
        // interface package
        step.addPackage(pkg);
    }
}
