const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const c = @import("common.zig");

const scale: u32 = 10;
const canvas_w: u32 = c.SCREEN_WIDTH / scale;
const canvas_h: u32 = c.SCREEN_HEIGHT / scale;

pub fn run() anyerror!void {
    var play_sim = false;
    var step = false;
    var draw_grid = true;

    var cells: [canvas_w * canvas_h]u8 = std.mem.zeroes([canvas_w * canvas_h]u8);
    var buffer: [canvas_w * canvas_h]u8 = std.mem.zeroes([canvas_w * canvas_h]u8);
    var pixels: [canvas_w * canvas_h]rl.Color = undefined;

    const tex = try rl.loadTextureFromImage(rl.genImageColor(canvas_w, canvas_h, .black));

    while (!rl.windowShouldClose() and !rl.isKeyPressed(.escape)) {
        const m_pos = rl.getMousePosition();

        // draw with mouse
        if (rl.isMouseButtonPressed(rl.MouseButton.left) and
            m_pos.x < c.SCREEN_WIDTH and
            m_pos.x > 0 and
            m_pos.y < c.SCREEN_HEIGHT and
            m_pos.y > 0)
        {
            const x: usize = @trunc(rl.getMousePosition().x / scale);
            const y: usize = @trunc(rl.getMousePosition().y / scale);

            const i = y * canvas_w + x;

            if (cells[i] == 0) {
                cells[i] = 1;
            } else {
                cells[i] = 0;
            }
        }

        if (play_sim or step) {
            cellSimulation(&cells, &buffer);

            cells = buffer;
            buffer = std.mem.zeroes([canvas_w * canvas_h]u8);

            if (step)
                step = false;
        }

        // pixel color update
        for (cells, 0..) |cell, i| {
            pixels[i] = if (cell != 0) c.rosepine.text else c.rosepine.base;
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.white);

        rl.updateTexture(tex, &pixels);
        rl.drawTextureEx(tex, rl.Vector2.init(0, 0), 0, scale, .white);

        if (draw_grid)
            drawGrid();

        // ui

        switch (play_sim) {
            true => {
                rl.drawText("PLAY", 5, 25, 20, .white);
            },
            false => {
                rl.drawText("PAUSE", 5, 25, 20, .white);
            },
        }

        const text = if (play_sim) "#132#" else "#131#";
        if (rg.button(.init(10, c.SCREEN_HEIGHT - 40, 30, 30), text)) {
            switch (play_sim) {
                true => {
                    play_sim = false;
                },
                false => {
                    play_sim = true;
                },
            }
        }

        if (rg.button(.init(50, c.SCREEN_HEIGHT - 40, 30, 30), "#134#"))
            step = true;

        if (rg.button(.init(90, c.SCREEN_HEIGHT - 40, 30, 30), "#28#"))
            cells = std.mem.zeroes([canvas_w * canvas_h]u8);

        if (rg.button(.init(130, c.SCREEN_HEIGHT - 40, 30, 30), "#97#")) {
            switch (draw_grid) {
                true => {
                    draw_grid = false;
                },
                false => {
                    draw_grid = true;
                },
            }
        }

        c.drawFPS();
    }
}

fn drawGrid() void {
    for (0..canvas_w) |i| {
        const index: i32 = @intCast(i);
        rl.drawLine(index * scale, 0, index * scale, c.SCREEN_HEIGHT, c.rosepine.highlight_med);
    }

    for (0..canvas_h) |i| {
        const index: i32 = @intCast(i);
        rl.drawLine(0, index * scale, c.SCREEN_WIDTH, index * scale, c.rosepine.highlight_med);
    }
}

fn cellSimulation(cells: []u8, buffer: []u8) void {
    for (cells, 0..) |cell, i| {
        _ = cell; // autofix
        const x = i % canvas_w;
        const y = i / canvas_w;

        var alive_count: u8 = 0;

        if (x > 0) {
            if (cells[i - 1] == 1) {
                alive_count += 1;
            }

            if (y > 0) {
                if (cells[i - canvas_w - 1] == 1) {
                    alive_count += 1;
                }
            }

            if (y < canvas_h - 1) {
                if (cells[i + canvas_w - 1] == 1) {
                    alive_count += 1;
                }
            }
        }

        if (x < canvas_w - 1) {
            if (cells[i + 1] == 1) {
                alive_count += 1;
            }

            if (y > 0) {
                if (cells[i - canvas_w + 1] == 1) {
                    alive_count += 1;
                }
            }

            if (y < canvas_h - 1) {
                if (cells[i + canvas_w + 1] == 1) {
                    alive_count += 1;
                }
            }
        }

        if (y > 0) {
            if (cells[i - canvas_w] == 1) {
                alive_count += 1;
            }
        }

        if (y < canvas_h - 1) {
            if (cells[i + canvas_w] == 1) {
                alive_count += 1;
            }
        }

        // apply rules
        if (cells[i] == 1) {
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
