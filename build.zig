const std = @import("std");

const sketches = [_][]const u8{
    "rain",
    "fractal-tree",
    "flocking",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const check = b.step("check", "Check if it compiles");

    for (sketches) |name| {
        const exe = b.addExecutable(.{
            .name = name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(b.fmt("src/{s}/main.zig", .{name})),
                .target = target,
                .optimize = optimize,
            }),
        });

        exe.root_module.linkLibrary(raylib_artifact);
        exe.root_module.addImport("raylib", raylib);
        exe.root_module.addImport("raygui", raygui);
        b.installArtifact(exe);

        exe.use_lld = true;
        exe.use_llvm = true;

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        const run_step = b.step(name, b.fmt("Run {s}", .{name}));
        run_step.dependOn(&run_cmd.step);

        check.dependOn(&exe.step);
    }
}
