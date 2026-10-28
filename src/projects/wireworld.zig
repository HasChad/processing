const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const c = @import("../common.zig");
const rp = c.rosepine;

const SCALE: u32 = 10;
const CANVAS_W: u32 = c.SCREEN_W / SCALE;
const CANVAS_H: u32 = c.SCREEN_H / SCALE;

const TOOLBAR_W: f32 = 290;
const TOOLBAR_H = 50;
const TOOLBAR = rl.Rectangle.init(0, c.SCREEN_H - TOOLBAR_H, TOOLBAR_W, TOOLBAR_H);

const Cell = enum {
    None,
    Wire,
    Head,
    Tail,
};

pub fn run() anyerror!void {
    var play_sim = false;
    var step = false;
    var draw_grid = true;

    var tick_rate: f32 = 60;
    var tick_acc: f32 = 0;

    var cells: [CANVAS_W * CANVAS_H]Cell = @splat(Cell.None);
    var buffer: [CANVAS_W * CANVAS_H]Cell = @splat(Cell.None);
    var pixels: [CANVAS_W * CANVAS_H]rl.Color = @splat(rp.base);

    const tex = try rl.loadTextureFromImage(rl.genImageColor(CANVAS_W, CANVAS_H, .black));
    defer rl.unloadTexture(tex);

    while (!rl.windowShouldClose() and !rl.isKeyPressed(.escape)) {
        const m_pos = rl.getMousePosition();
        const in_canvas = m_pos.x > 0 and m_pos.x < c.SCREEN_W and m_pos.y > 0 and m_pos.y < c.SCREEN_H;
        const can_draw = in_canvas and !rl.checkCollisionPointRec(m_pos, TOOLBAR);

        // draw with mouse
        if (rl.isMouseButtonPressed(rl.MouseButton.left) and can_draw) {
            const x: usize = @trunc(m_pos.x / SCALE);
            const y: usize = @trunc(m_pos.y / SCALE);

            const i = y * CANVAS_W + x;

            cells[i] = switch (cells[i]) {
                .None => .None,
                .Wire => .Head,
                .Head => .Tail,
                .Tail => .Wire,
            };
        }

        if (rl.isMouseButtonDown(rl.MouseButton.left) and can_draw) {
            const x: usize = @trunc(m_pos.x / SCALE);
            const y: usize = @trunc(m_pos.y / SCALE);

            const i = y * CANVAS_W + x;

            if (cells[i] == .None)
                cells[i] = .Wire;
        }

        // draw with mouse

        // erase
        if (rl.isMouseButtonDown(rl.MouseButton.right) and can_draw) {
            const x: usize = @trunc(m_pos.x / SCALE);
            const y: usize = @trunc(m_pos.y / SCALE);

            const i = y * CANVAS_W + x;

            cells[i] = .None;
        }

        if (play_sim) {
            const tick_duration: f32 = 1.0 / tick_rate;
            tick_acc += rl.getFrameTime();

            if (tick_acc > tick_duration) {
                cellSimulation(&cells, &buffer);

                cells = buffer;
                buffer = std.mem.zeroes([CANVAS_W * CANVAS_H]Cell);

                tick_acc -= tick_duration;
            }
        } else if (step) {
            cellSimulation(&cells, &buffer);

            cells = buffer;
            buffer = std.mem.zeroes([CANVAS_W * CANVAS_H]Cell);

            step = false;
        }

        // pixel color update
        for (cells, 0..) |cell, i| {
            pixels[i] = blk: {
                if (cell == .Wire) break :blk rp.muted;
                if (cell == .Head) break :blk rp.text;
                if (cell == .Tail) break :blk rp.iris;
                break :blk rp.base;
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

        renderUI(&play_sim, &step, &cells, &draw_grid, &tick_rate);

        c.drawFPS();
    }
}

fn drawGrid() void {
    for (0..CANVAS_W) |i| {
        const index: i32 = @intCast(i);
        rl.drawLine(index * SCALE, 0, index * SCALE, c.SCREEN_H, rp.overlay);
    }

    for (0..CANVAS_H) |i| {
        const index: i32 = @intCast(i);
        rl.drawLine(0, index * SCALE, c.SCREEN_W, index * SCALE, rp.overlay);
    }
}

fn cellSimulation(cells: []Cell, buffer: []Cell) void {
    for (cells, 0..) |cell, i| {
        const x = i % CANVAS_W;
        const y = i / CANVAS_W;

        const l = x > 0;
        const r = x < CANVAS_W - 1;
        const u = y > 0;
        const d = y < CANVAS_H - 1;

        switch (cell) {
            .None => {},
            .Wire => {
                var count: u4 = 0;
                if (l and cells[i - 1] == .Head) count += 1;
                if (r and cells[i + 1] == .Head) count += 1;
                if (u and cells[i - CANVAS_W] == .Head) count += 1;
                if (d and cells[i + CANVAS_W] == .Head) count += 1;

                if (l and u and cells[i - 1 - CANVAS_W] == .Head) count += 1;
                if (l and d and cells[i - 1 + CANVAS_W] == .Head) count += 1;
                if (r and u and cells[i + 1 - CANVAS_W] == .Head) count += 1;
                if (r and d and cells[i + 1 + CANVAS_W] == .Head) count += 1;

                buffer[i] = if (count >= 1 and count <= 2) .Head else .Wire;
            },
            .Head => {
                buffer[i] = .Tail;
            },
            .Tail => {
                buffer[i] = .Wire;
            },
        }
    }
}

fn renderUI(play_sim: *bool, step: *bool, cells: []Cell, draw_grid: *bool, tick_rate: *f32) void {
    rl.drawRectangleRec(TOOLBAR, rp.highlight_med);

    switch (play_sim.*) {
        true => {
            rl.drawText("PLAY", 5, 25, 20, .white);
        },
        false => {
            rl.drawText("PAUSE", 5, 25, 20, .white);
        },
    }

    const text = if (play_sim.*) "#132#" else "#131#";
    if (rg.button(.init(10, c.SCREEN_H - 40, 30, 30), text)) {
        switch (play_sim.*) {
            true => {
                play_sim.* = false;
            },
            false => {
                play_sim.* = true;
            },
        }
    }

    if (rg.button(.init(50, c.SCREEN_H - 40, 30, 30), "#134#"))
        step.* = true;

    if (rg.button(.init(90, c.SCREEN_H - 40, 30, 30), "#28#"))
        @memset(cells, .None);

    if (rg.button(.init(130, c.SCREEN_H - 40, 30, 30), "#97#")) {
        switch (draw_grid.*) {
            true => {
                draw_grid.* = false;
            },
            false => {
                draw_grid.* = true;
            },
        }
    }

    _ = rg.sliderBar(
        rl.Rectangle{
            .x = 170,
            .y = c.SCREEN_H - 35,
            .width = 100,
            .height = 20,
        },

        "",
        rl.textFormat("%02.00f", .{tick_rate.*}),
        tick_rate,
        1,
        60,
    );
}
