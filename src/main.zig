const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const c = @import("common.zig");

const rain_sketch = @import("projects/rain.zig");
const fractal_tree_sketch = @import("projects/fractal-tree.zig");
const flocking_sketch = @import("projects/flocking.zig");
const verlet_physics_sketch = @import("projects/verlet-physics.zig");
const verlet_chain_sketch = @import("projects/verlet-chain.zig");
const gol_sketch = @import("projects/game-of-life.zig");
const pixel_fire_sketch = @import("projects/pixel-fire.zig");
const falling_sand_sketch = @import("projects/falling-sand.zig");
const wireworld_sketch = @import("projects/wireworld.zig");

const Project = enum {
    MainMenu,
    Rain,
    FractalTree,
    Flocking,
    VerletPhysics,
    VerletChain,
    GameOfLife,
    PixelFire,
    FallingSand,
    Wireworld,
    Quit,
};

pub fn main(init: std.process.Init) anyerror!void {
    const io = init.io;
    const rng_impl: std.Random.IoSource = .{ .io = io };
    const rand = rng_impl.interface();

    rl.initWindow(c.SCREEN_W, c.SCREEN_H, "Zig Processing");
    defer rl.closeWindow();
    rl.setExitKey(.null);
    rl.setTargetFPS(60);

    var current_project = Project.Wireworld;

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
            .PixelFire => {
                try pixel_fire_sketch.run(rand);
                current_project = .MainMenu;
            },
            .FallingSand => {
                try falling_sand_sketch.run(rand);
                current_project = .MainMenu;
            },
            .Wireworld => {
                try wireworld_sketch.run();
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
        @divTrunc(c.SCREEN_W - width, 2),
        20,
        font_size,
        c.getRainbow(@floatCast(rl.getTime())),
    );

    if (rg.button(.init(c.SCREEN_W / 2 - 60, 100, 120, 30), "Rain"))
        current_project.* = .Rain;

    if (rg.button(.init(c.SCREEN_W / 2 - 60, 140, 120, 30), "Fractal Tree"))
        current_project.* = .FractalTree;

    if (rg.button(.init(c.SCREEN_W / 2 - 60, 180, 120, 30), "Flocking"))
        current_project.* = .Flocking;

    if (rg.button(.init(c.SCREEN_W / 2 - 60, 220, 120, 30), "Verlet Physics"))
        current_project.* = .VerletPhysics;

    if (rg.button(.init(c.SCREEN_W / 2 - 60, 260, 120, 30), "Verlet Chain"))
        current_project.* = .VerletChain;

    if (rg.button(.init(c.SCREEN_W / 2 - 60, 300, 120, 30), "Game of Life"))
        current_project.* = .GameOfLife;

    if (rg.button(.init(c.SCREEN_W / 2 - 60, 340, 120, 30), "Pixel Fire"))
        current_project.* = .PixelFire;

    if (rg.button(.init(c.SCREEN_W / 2 - 60, 380, 120, 30), "Falling Sand"))
        current_project.* = .FallingSand;

    if (rg.button(.init(c.SCREEN_W / 2 - 60, 420, 120, 30), "Wireworld"))
        current_project.* = .Wireworld;

    if (c.colorButton(.init(c.SCREEN_W / 2 - 60, c.SCREEN_H - 40, 120, 30), "Quit", c.rosepine.love))
        current_project.* = .Quit;
}
