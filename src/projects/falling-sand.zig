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
    _ = rand; // autofix

    var draw_grid = true;

    const tick_rate: f32 = 60;
    var tick_acc: f32 = 0;

    var cells: [CANVAS_W * CANVAS_H]Material = @splat(.None);
    var buffer: [CANVAS_W * CANVAS_H]Material = @splat(.None);
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
                cells[i] = .Sand;
        }

        const tick_duration: f32 = 1.0 / tick_rate;
        tick_acc += rl.getFrameTime();

        if (tick_acc > tick_duration) {
            cellSimulation(&cells, &buffer);

            cells = buffer;
            buffer = std.mem.zeroes([CANVAS_W * CANVAS_H]Material);

            tick_acc -= tick_duration;
        }

        // pixel color update
        for (cells, 0..) |cell, i| {
            pixels[i] = if (cell == .None) c.rosepine.base else c.rosepine.text;
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.updateTexture(tex, &pixels);
        rl.drawTextureEx(tex, rl.Vector2.init(0, 0), 0, SCALE, .white);

        if (draw_grid) {
            drawGrid();
        }

        renderUI(&cells, &draw_grid);

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

fn cellSimulation(cells: []Material, buffer: []Material) void {
    for (cells, 0..) |cell, i| {
        const x = i % CANVAS_W;
        const y = i / CANVAS_W;

        if (cell == .Sand) {
            buffer[i] = .Sand;

            if (y < CANVAS_H - 1) {
                if (cells[i + CANVAS_W] == .None) {
                    buffer[i] = .None;
                    buffer[i + CANVAS_W] = .Sand;
                } else if (x > 0 and cells[i + CANVAS_W - 1] == .None) {
                    buffer[i] = .None;
                    buffer[i + CANVAS_W - 1] = .Sand;
                } else if (x < CANVAS_W - 1 and cells[i + CANVAS_W + 1] == .None) {
                    buffer[i] = .None;
                    buffer[i + CANVAS_W + 1] = .Sand;
                }
            }
        }
    }
}

fn renderUI(cells: []Material, draw_grid: *bool) void {
    if (rg.button(.init(10, c.SCREEN_HEIGHT - 40, 30, 30), "#28#"))
        @memset(cells, .None);

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
}
