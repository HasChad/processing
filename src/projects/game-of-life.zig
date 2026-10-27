const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const c = @import("../common.zig");
const rp = c.rosepine;

const SCALE: u32 = 10;
const CANVAS_W: u32 = c.SCREEN_WIDTH / SCALE;
const CANVAS_H: u32 = c.SCREEN_HEIGHT / SCALE;

pub fn run() anyerror!void {
    var play_sim = false;
    var step = false;
    var draw_grid = true;

    var tick_rate: f32 = 60;
    var tick_acc: f32 = 0;

    var cells: [CANVAS_W * CANVAS_H]u8 = @splat(0);
    var buffer: [CANVAS_W * CANVAS_H]u8 = @splat(0);
    var pixels: [CANVAS_W * CANVAS_H]rl.Color = @splat(rp.base);

    const tex = try rl.loadTextureFromImage(rl.genImageColor(CANVAS_W, CANVAS_H, .black));
    defer rl.unloadTexture(tex);

    while (!rl.windowShouldClose() and !rl.isKeyPressed(.escape)) {
        const m_pos = rl.getMousePosition();

        // draw with mouse
        if (rl.isMouseButtonPressed(rl.MouseButton.left) and
            m_pos.x < c.SCREEN_WIDTH and
            m_pos.x > 0 and
            m_pos.y < c.SCREEN_HEIGHT and
            m_pos.y > 0)
        {
            const x: usize = @trunc(m_pos.x / SCALE);
            const y: usize = @trunc(m_pos.y / SCALE);

            const i = y * CANVAS_W + x;

            if (cells[i] == 0) {
                cells[i] = 1;
            } else {
                cells[i] = 0;
            }
        }

        if (play_sim) {
            const tick_duration: f32 = 1.0 / tick_rate;
            tick_acc += rl.getFrameTime();

            if (tick_acc > tick_duration) {
                cellSimulation(&cells, &buffer);

                cells = buffer;
                buffer = std.mem.zeroes([CANVAS_W * CANVAS_H]u8);

                tick_acc -= tick_duration;
            }
        }

        if (!play_sim and step) {
            cellSimulation(&cells, &buffer);

            cells = buffer;
            buffer = std.mem.zeroes([CANVAS_W * CANVAS_H]u8);

            if (step)
                step = false;
        }

        // pixel color update
        for (cells, 0..) |cell, i| {
            pixels[i] = if (cell != 0) rp.text else rp.base;
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
        rl.drawLine(index * SCALE, 0, index * SCALE, c.SCREEN_HEIGHT, rp.highlight_med);
    }

    for (0..CANVAS_H) |i| {
        const index: i32 = @intCast(i);
        rl.drawLine(0, index * SCALE, c.SCREEN_WIDTH, index * SCALE, rp.highlight_med);
    }
}

fn cellSimulation(cells: []u8, buffer: []u8) void {
    for (cells, 0..) |cell, i| {
        const x = i % CANVAS_W;
        const y = i / CANVAS_W;

        var alive_count: u8 = 0;

        if (x > 0) {
            if (cells[i - 1] == 1)
                alive_count += 1;

            if (y > 0) {
                if (cells[i - CANVAS_W - 1] == 1)
                    alive_count += 1;
            }

            if (y < CANVAS_H - 1) {
                if (cells[i + CANVAS_W - 1] == 1)
                    alive_count += 1;
            }
        }

        if (x < CANVAS_W - 1) {
            if (cells[i + 1] == 1)
                alive_count += 1;

            if (y > 0) {
                if (cells[i - CANVAS_W + 1] == 1)
                    alive_count += 1;
            }

            if (y < CANVAS_H - 1) {
                if (cells[i + CANVAS_W + 1] == 1)
                    alive_count += 1;
            }
        }

        if (y > 0) {
            if (cells[i - CANVAS_W] == 1)
                alive_count += 1;
        }

        if (y < CANVAS_H - 1) {
            if (cells[i + CANVAS_W] == 1)
                alive_count += 1;
        }

        // apply rules
        if (cell == 1) {
            if (alive_count < 2) {
                buffer[i] = 0;
            } else if (alive_count > 3) {
                buffer[i] = 0;
            } else {
                buffer[i] = 1;
            }
        } else if (alive_count == 3) {
            buffer[i] = 1;
        }
    }
}

fn renderUI(play_sim: *bool, step: *bool, cells: []u8, draw_grid: *bool, tick_rate: *f32) void {
    switch (play_sim.*) {
        true => {
            rl.drawText("PLAY", 5, 25, 20, .white);
        },
        false => {
            rl.drawText("PAUSE", 5, 25, 20, .white);
        },
    }

    const text = if (play_sim.*) "#132#" else "#131#";
    if (rg.button(.init(10, c.SCREEN_HEIGHT - 40, 30, 30), text)) {
        switch (play_sim.*) {
            true => {
                play_sim.* = false;
            },
            false => {
                play_sim.* = true;
            },
        }
    }

    if (rg.button(.init(50, c.SCREEN_HEIGHT - 40, 30, 30), "#134#"))
        step.* = true;

    if (rg.button(.init(90, c.SCREEN_HEIGHT - 40, 30, 30), "#28#"))
        @memset(cells, 0);

    if (rg.button(.init(130, c.SCREEN_HEIGHT - 40, 30, 30), "#97#")) {
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
            .y = c.SCREEN_HEIGHT - 35,
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
