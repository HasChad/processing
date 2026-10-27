const std = @import("std");
const rl = @import("raylib");
const c = @import("../common.zig");
const rp = c.rosepine;

const SCALE: u32 = 5;
const CANVAS_W: u32 = c.SCREEN_WIDTH / SCALE;
const CANVAS_H: u32 = c.SCREEN_HEIGHT / SCALE;
const MAX_HEAT: u8 = 35;

pub fn run(rand: std.Random) anyerror!void {
    const tick_rate: f32 = 30;
    const tick_duration: f32 = 1.0 / tick_rate;
    var tick_acc: f32 = 0;

    var enable_fire = true;

    var cells: [CANVAS_W * CANVAS_H]u8 = @splat(0);
    var pixels: [CANVAS_W * CANVAS_H]rl.Color = @splat(rp.base);

    const tex = try rl.loadTextureFromImage(rl.genImageColor(CANVAS_W, CANVAS_H, .black));
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
            cellSimulation(
                rand,
                &enable_fire,
                &cells,
            );

            tick_acc -= tick_duration;
        }

        // pixel color update
        for (cells, 0..) |cell, i| {
            pixels[i] = heatColor(cell);
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rp.base);

        rl.updateTexture(tex, &pixels);
        rl.drawTextureEx(tex, rl.Vector2.init(0, 0), 0, SCALE, .white);

        c.drawFPS();
    }
}

fn cellSimulation(rand: std.Random, enable_fire: *bool, cells: []u8) void {
    for (0..cells.len) |i| {
        const x = i % CANVAS_W;
        const y = i / CANVAS_W;

        if (y == CANVAS_H - 1) {
            cells[i] = if (enable_fire.*) MAX_HEAT else 0;
        } else {
            const rng = rand.uintAtMost(usize, 3);
            const dst_x = (x + CANVAS_W + 1 - rng) % CANVAS_W;
            cells[y * CANVAS_W + dst_x] = cells[(y + 1) * CANVAS_W + x] -| @as(u8, @intCast(rng & 1));
        }
    }
}

fn heatColor(cell: u8) rl.Color {
    const t = @as(f32, @floatFromInt(cell)) / @as(f32, @floatFromInt(MAX_HEAT)) * 3.0;

    const r = @min(t, 1.0);
    const g = std.math.clamp(t - 1.0, 0.0, 1.0);
    const b = std.math.clamp(t - 2.0, 0.0, 1.0);

    return rl.Color.init(
        @intFromFloat(r * 255),
        @intFromFloat(g * 255),
        @intFromFloat(b * 255),
        255,
    );
}
