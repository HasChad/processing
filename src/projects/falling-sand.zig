const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const c = @import("../common.zig");

const SCALE: u32 = 10;
const CANVAS_W: u32 = c.SCREEN_WIDTH / SCALE;
const CANVAS_H: u32 = c.SCREEN_HEIGHT / SCALE;

const Material = enum {
    None,
    Sand,
    Water,
    Stone,
};

pub fn run(rand: std.Random) anyerror!void {
    var draw_grid = false;
    var left_to_right = true;

    const tick_rate: f32 = 60;
    const tick_duration: f32 = 1.0 / tick_rate;
    var tick_acc: f32 = 0;

    var brush = Material.Sand;
    var cells: [CANVAS_W * CANVAS_H]Material = @splat(Material.None);
    var moved: [CANVAS_W * CANVAS_H]bool = @splat(false);
    var pixels: [CANVAS_W * CANVAS_H]rl.Color = @splat(c.rosepine.base);

    const tex = try rl.loadTextureFromImage(rl.genImageColor(CANVAS_W, CANVAS_H, .black));
    defer rl.unloadTexture(tex);

    while (!rl.windowShouldClose() and !rl.isKeyPressed(.escape)) {
        const m_pos = rl.getMousePosition();

        // draw with mouse
        if (rl.isMouseButtonDown(rl.MouseButton.left) and
            m_pos.x < c.SCREEN_WIDTH and
            m_pos.x > 0 and
            m_pos.y < c.SCREEN_HEIGHT and
            m_pos.y > 0)
        {
            const x: usize = @trunc(m_pos.x / SCALE);
            const y: usize = @trunc(m_pos.y / SCALE);

            const i = y * CANVAS_W + x;

            if (cells[i] == .None)
                cells[i] = brush;
        }

        // erase
        if (rl.isMouseButtonDown(rl.MouseButton.right) and
            m_pos.x < c.SCREEN_WIDTH and
            m_pos.x > 0 and
            m_pos.y < c.SCREEN_HEIGHT and
            m_pos.y > 0)
        {
            const x: usize = @trunc(m_pos.x / SCALE);
            const y: usize = @trunc(m_pos.y / SCALE);

            const i = y * CANVAS_W + x;

            if (cells[i] != .None)
                cells[i] = Material.None;
        }

        // simulation
        tick_acc += rl.getFrameTime();
        if (tick_acc > tick_duration) {
            @memset(&moved, false);
            cellSimulation(&cells, &moved, &left_to_right, rand);
            left_to_right = !left_to_right;

            tick_acc -= tick_duration;
        }

        // pixel color update
        for (cells, 0..) |cell, i| {
            pixels[i] = blk: {
                if (cell == .Sand) break :blk c.rosepine.gold;
                if (cell == .Water) break :blk c.rosepine.iris;
                if (cell == .Stone) break :blk c.rosepine.muted;
                break :blk c.rosepine.base;
            };
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.updateTexture(tex, &pixels);
        rl.drawTextureEx(tex, rl.Vector2.init(0, 0), 0, SCALE, .white);

        if (draw_grid) {
            drawGrid();
        }

        renderUI(&cells, &draw_grid, &brush);

        c.drawFPS();
    }
}

fn drawGrid() void {
    for (0..CANVAS_W) |i| {
        const index: i32 = @intCast(i);
        rl.drawLine(index * SCALE, 0, index * SCALE, c.SCREEN_HEIGHT, c.rosepine.highlight_med);
    }

    for (0..CANVAS_H) |i| {
        const index: i32 = @intCast(i);
        rl.drawLine(0, index * SCALE, c.SCREEN_WIDTH, index * SCALE, c.rosepine.highlight_med);
    }
}

fn cellSimulation(cells: []Material, moved: []bool, left_to_right: *bool, rand: std.Random) void {
    var y: usize = CANVAS_H;
    while (y > 0) {
        y -= 1;
        for (0..CANVAS_W) |col| {
            const x = if (left_to_right.*) col else CANVAS_W - 1 - col;
            const i = y * CANVAS_W + x;
            const cell = cells[i];

            if (moved[i] == true)
                continue;

            switch (cell) {
                .None => {},
                .Sand => {
                    if (y < CANVAS_H - 1) {
                        const below = i + CANVAS_W;
                        const dl = x > 0 and cells[i + CANVAS_W - 1] == .None;
                        const dr = x < CANVAS_W - 1 and cells[i + CANVAS_W + 1] == .None;

                        if (cells[below] == .None) {
                            cells[i] = .None;
                            cells[i + CANVAS_W] = .Sand;
                            moved[i + CANVAS_W] = true;
                        } else if (cells[below] == .Water) {
                            cells[i] = .Water;
                            cells[i + CANVAS_W] = .Sand;
                            moved[i] = true;
                            moved[i + CANVAS_W] = true;
                        } else if (dl and dr) {
                            const target = if (rand.boolean()) i + CANVAS_W - 1 else i + CANVAS_W + 1;
                            cells[i] = .None;
                            cells[target] = .Sand;
                            moved[target] = true;
                        } else if (dl) {
                            cells[i] = .None;
                            cells[i + CANVAS_W - 1] = .Sand;
                            moved[i + CANVAS_W - 1] = true;
                        } else if (dr) {
                            cells[i] = .None;
                            cells[i + CANVAS_W + 1] = .Sand;
                            moved[i + CANVAS_W + 1] = true;
                        }
                    }
                },
                .Water => {
                    const l = x > 0 and cells[i - 1] == .None;
                    const r = x < CANVAS_W - 1 and cells[i + 1] == .None;

                    if (y < CANVAS_H - 1) {
                        const below = i + CANVAS_W;
                        const dl = x > 0 and cells[i + CANVAS_W - 1] == .None;
                        const dr = x < CANVAS_W - 1 and cells[i + CANVAS_W + 1] == .None;

                        if (cells[below] == .None) {
                            cells[i] = .None;
                            cells[i + CANVAS_W] = .Water;
                            moved[i + CANVAS_W] = true;
                        } else if (dl and dr) {
                            const target = if (rand.boolean()) i + CANVAS_W - 1 else i + CANVAS_W + 1;
                            cells[i] = .None;
                            cells[target] = .Water;
                            moved[target] = true;
                        } else if (dl) {
                            cells[i] = .None;
                            cells[i + CANVAS_W - 1] = .Water;
                            moved[i + CANVAS_W - 1] = true;
                        } else if (dr) {
                            cells[i] = .None;
                            cells[i + CANVAS_W + 1] = .Water;
                            moved[i + CANVAS_W + 1] = true;
                        } else if (l and r) {
                            const target = if (rand.boolean()) i - 1 else i + 1;
                            cells[i] = .None;
                            cells[target] = .Water;
                            moved[target] = true;
                        } else if (l) {
                            cells[i] = .None;
                            cells[i - 1] = .Water;
                            moved[i - 1] = true;
                        } else if (r) {
                            cells[i] = .None;
                            cells[i + 1] = .Water;
                            moved[i + 1] = true;
                        }
                    } else {
                        if (l) {
                            cells[i] = .None;
                            cells[i - 1] = .Water;
                            moved[i - 1] = true;
                        } else if (r) {
                            cells[i] = .None;
                            cells[i + 1] = .Water;
                            moved[i + 1] = true;
                        }
                    }
                },
                .Stone => {},
            }
        }
    }

    left_to_right.* = !left_to_right.*;
}

fn renderUI(cells: []Material, draw_grid: *bool, brush: *Material) void {
    if (rg.button(.init(10, c.SCREEN_HEIGHT - 40, 30, 30), "#28#"))
        @memset(cells, Material.None);

    if (rg.button(.init(50, c.SCREEN_HEIGHT - 40, 30, 30), "#97#")) {
        switch (draw_grid.*) {
            true => {
                draw_grid.* = false;
            },
            false => {
                draw_grid.* = true;
            },
        }
    }

    if (rg.button(.init(90, c.SCREEN_HEIGHT - 40, 30, 30), "Sa"))
        brush.* = .Sand;

    if (rg.button(.init(130, c.SCREEN_HEIGHT - 40, 30, 30), "Wa"))
        brush.* = .Water;

    if (rg.button(.init(170, c.SCREEN_HEIGHT - 40, 30, 30), "St"))
        brush.* = .Stone;
}
