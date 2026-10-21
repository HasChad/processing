const std = @import("std");
const rl = @import("raylib");
const c = @import("../common.zig");

const scale: u32 = 10;
const canvas_w: u32 = c.SCREEN_WIDTH / scale;
const canvas_h: u32 = c.SCREEN_HEIGHT / scale;

pub fn run(rand: std.Random) anyerror!void {
    const tick_rate: f32 = 30;
    const tick_duration: f32 = 1.0 / tick_rate;
    var tick_acc: f32 = 0;

    var enable_fire = true;

    var cells: [canvas_w * canvas_h]u8 = @splat(0);
    var buffer: [canvas_w * canvas_h]u8 = @splat(0);
    var pixels: [canvas_w * canvas_h]rl.Color = @splat(c.rosepine.base);

    const tex = try rl.loadTextureFromImage(rl.genImageColor(canvas_w, canvas_h, .black));
    defer rl.unloadTexture(tex);

    while (!rl.windowShouldClose() and !rl.isKeyPressed(.escape)) {
        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            switch (enable_fire) {
                true => enable_fire = false,
                false => enable_fire = true,
            }
        }
        // simulation
        tick_acc += rl.getFrameTime();

        if (tick_acc > tick_duration) {
            cellSimulation(rand, &enable_fire, &cells, &buffer);

            cells = buffer;
            buffer = std.mem.zeroes([canvas_w * canvas_h]u8);

            tick_acc -= tick_duration;
        }

        // pixel color update
        for (cells, 0..) |cell, i| {
            const color = if (cell > 23) c: {
                const num = 21 * (cell - 23);

                break :c rl.Color.init(255, 255, num, 255);
            } else if (cell > 11) c: {
                const num = 21 * (cell - 11);

                break :c rl.Color.init(255, num, 0, 255);
            } else c: {
                const num = 21 * cell;

                break :c rl.Color.init(num, 0, 0, 255);
            };

            pixels[i] = color;
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(c.rosepine.base);

        rl.updateTexture(tex, &pixels);
        rl.drawTextureEx(tex, rl.Vector2.init(0, 0), 0, scale, .white);

        c.drawFPS();
    }
}

fn cellSimulation(rand: std.Random, enable_fire: *bool, cells: []u8, buffer: []u8) void {
    for (cells, 0..) |_, i| {
        const x = i % canvas_w;
        const y = i / canvas_w;

        if (y == canvas_h - 1) {
            if (enable_fire.*) {
                buffer[i] = 35;
            } else {
                buffer[i] = 0;
            }
        } else {
            var shift = rand.uintAtMost(u8, 2);

            if (x + shift > canvas_w - 1) {
                shift = 0;
            }

            const lower_cell = cells[i + canvas_w + shift];

            if (lower_cell >= 2) {
                buffer[i] = lower_cell - rand.uintAtMost(u8, 2);
            } else if (lower_cell == 1) {
                buffer[i] = 0;
            }
        }
    }
}
