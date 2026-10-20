const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const c = @import("common.zig");

const rain_sketch = @import("rain.zig");
const fractal_tree_sketch = @import("fractal-tree.zig");
const flocking_sketch = @import("flocking.zig");
const verlet_physics_sketch = @import("verlet-physics.zig");
const verlet_chain_sketch = @import("verlet-chain.zig");
const gol_sketch = @import("game-of-life.zig");

const Project = enum {
    MainMenu,
    Rain,
    FractalTree,
    Flocking,
    VerletPhysics,
    VerletChain,
    GameOfLife,
    Quit,
};

pub fn main(init: std.process.Init) anyerror!void {
    const io = init.io;
    const rng_impl: std.Random.IoSource = .{ .io = io };
    const rand = rng_impl.interface();

    rl.initWindow(c.SCREEN_WIDTH, c.SCREEN_HEIGHT, "Zig Processing");
    defer rl.closeWindow();
    rl.setExitKey(.null);
    rl.setTargetFPS(60);

    var current_project = Project.MainMenu;

    while (!rl.windowShouldClose()) {
        {}

        switch (current_project) {
            .MainMenu => {
                mainMenu(&current_project);
            },
            .Rain => {
                try rain_sketch.run(rand);
                current_project = .MainMenu;
            },
            .FractalTree => {
                try fractal_tree_sketch.run();
                current_project = .MainMenu;
            },
            .Flocking => {
                try flocking_sketch.run(rand);
                current_project = .MainMenu;
            },
            .VerletPhysics => {
                try verlet_physics_sketch.run(rand);
                current_project = .MainMenu;
            },
            .VerletChain => {
                try verlet_chain_sketch.run(rand);
                current_project = .MainMenu;
            },
            .GameOfLife => {
                try gol_sketch.run();
                current_project = .MainMenu;
            },
            .Quit => {
                break;
            },
        }
    }
}

fn mainMenu(current_project: *Project) void {
    rl.beginDrawing();
    defer rl.endDrawing();
    rl.clearBackground(c.rosepine.base);

    const title = "Zig Processing";
    const font_size = 60;
    const width = rl.measureText(title, font_size);
    rl.drawText(
        title,
        @divTrunc(c.SCREEN_WIDTH - width, 2),
        40,
        font_size,
        c.getRainbow(@floatCast(rl.getTime())),
    );

    if (rg.button(.init(20, 100, 120, 30), "Rain"))
        current_project.* = .Rain;

    if (rg.button(.init(20, 140, 120, 30), "Fractal Tree"))
        current_project.* = .FractalTree;

    if (rg.button(.init(20, 180, 120, 30), "Flocking"))
        current_project.* = .Flocking;

    if (rg.button(.init(20, 220, 120, 30), "Verlet Physics"))
        current_project.* = .VerletPhysics;

    if (rg.button(.init(20, 260, 120, 30), "Verlet Chain"))
        current_project.* = .VerletChain;

    if (rg.button(.init(20, 300, 120, 30), "Game of Life"))
        current_project.* = .GameOfLife;

    if (c.colorButton(.init(c.SCREEN_WIDTH / 2 - 60, c.SCREEN_HEIGHT - 40, 120, 30), "Quit", c.rosepine.love))
        current_project.* = .Quit;
}
