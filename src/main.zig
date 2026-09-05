const std = @import("std");
const rl = @import("raylib");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 600;
const BG_COLOR = rl.Color{ .r = 25, .g = 23, .b = 36, .a = 255 };

const Project = enum {
    MainMenu,
    Rain,
    FractalTree,
    Flocking,
    VerletPhysics,
    VerletChain,
};

pub fn main(init: std.process.Init) anyerror!void {
    const io = init.io;
    const rng_impl: std.Random.IoSource = .{ .io = io };
    const rand = rng_impl.interface();
    _ = rand;

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Zig Processing");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    const current_project = Project.MainMenu;

    while (!rl.windowShouldClose()) {

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(BG_COLOR);

        switch (current_project) {
            .MainMenu => {},
            .Rain => {},
            .FractalTree => {},
            .Flocking => {},
            .VerletPhysics => {},
            .VerletChain => {},
        }

        rl.drawText(rl.textFormat("%i FPS", .{rl.getFPS()}), 5, 5, 20, .white);
    }
}
