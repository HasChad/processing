const std = @import("std");
const rl = @import("raylib");
const c = @import("common.zig");

const scale: u32 = 20;
const canvas_w: u32 = c.SCREEN_WIDTH / scale;
const canvas_h: u32 = c.SCREEN_HEIGHT / scale;

pub fn run(rand: std.Random) anyerror!void {
    const tick_rate: f32 = 60;
    const tick_duration: f32 = 1.0 / tick_rate;
    var tick_acc: f32 = 0;

    var cells: [canvas_w * canvas_h]u8 = @splat(0);
    var buffer: [canvas_w * canvas_h]u8 = @splat(0);
    var pixels: [canvas_w * canvas_h]rl.Color = @splat(c.rosepine.base);

    const tex = try rl.loadTextureFromImage(rl.genImageColor(canvas_w, canvas_h, .black));

    while (!rl.windowShouldClose() and !rl.isKeyPressed(.escape)) {
        // simulation
        tick_acc += rl.getFrameTime();

        if (tick_acc > tick_duration) {
            cellSimulation(rand, &cells, &buffer);

            cells = buffer;
            buffer = std.mem.zeroes([canvas_w * canvas_h]u8);

            tick_acc -= tick_duration;
        }

        // pixel color update
        for (cells, 0..) |cell, i| {
            const mul: f32 = 255.0 / 35.0;

            const alpha: f32 = cell * mul;
            const color = rl.Color.white.alpha(alpha);

            pixels[i] = color;
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(c.rosepine.base);

        rl.updateTexture(tex, &pixels);
        rl.drawTextureEx(tex, rl.Vector2.init(0, 0), 0, scale, .white);

        drawGrid();

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

fn cellSimulation(rand: std.Random, cells: []u8, buffer: []u8) void {
    _ = rand; // autofix
    for (cells, 0..) |_, i| {
        const x = i % canvas_w;
        const y = i / canvas_w;

        var alive_count: u8 = 0;

        if (x > 0) {
            if (cells[i - 1] == 1)
                alive_count += 1;

            if (y > 0) {
                if (cells[i - canvas_w - 1] == 1)
                    alive_count += 1;
            }

            if (y < canvas_h - 1) {
                if (cells[i + canvas_w - 1] == 1)
                    alive_count += 1;
            }
        }

        if (x < canvas_w - 1) {
            if (cells[i + 1] == 1)
                alive_count += 1;

            if (y > 0) {
                if (cells[i - canvas_w + 1] == 1)
                    alive_count += 1;
            }

            if (y < canvas_h - 1) {
                if (cells[i + canvas_w + 1] == 1)
                    alive_count += 1;
            }
        }

        if (y > 0) {
            if (cells[i - canvas_w] == 1)
                alive_count += 1;
        }

        if (y < canvas_h - 1) {
            if (cells[i + canvas_w] == 1)
                alive_count += 1;
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
