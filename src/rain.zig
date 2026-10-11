const std = @import("std");
const rl = @import("raylib");
const c = @import("common.zig");

const RAIN_COUNT = 200;

const Drop = struct {
    x: f32,
    y: f32,
    vy: f32,

    pub fn init(rand: std.Random) Drop {
        return Drop{
            .x = rand.float(f32) * c.SCREEN_WIDTH,
            .y = rand.float(f32) * 500 - 700,
            .vy = rand.float(f32) * 1000 + 500,
        };
    }

    pub fn draw(self: Drop) void {
        var color = c.rosepine.subtle;

        const alpha_f = (self.vy / 1500.0) * 255;
        color.a = @intFromFloat(alpha_f);

        rl.drawRectangle(
            @intFromFloat(self.x),
            @intFromFloat(self.y),
            @intFromFloat(self.vy / 300),
            @intFromFloat(self.vy / 10),
            color,
        );
    }

    pub fn move(self: *Drop, rand: std.Random) void {
        self.y += self.vy * rl.getFrameTime();

        if (self.y > c.SCREEN_HEIGHT) {
            self.* = Drop.init(rand);
        }
    }
};

pub fn run(rand: std.Random) anyerror!void {
    var rain: [RAIN_COUNT]Drop = undefined;

    for (&rain) |*drop| {
        drop.* = Drop.init(rand);
    }

    while (!rl.windowShouldClose() and !rl.isKeyPressed(.escape)) {
        for (&rain) |*drop| {
            drop.*.move(rand);
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(c.rosepine.base);

        for (&rain) |*drop| {
            drop.*.draw();
        }

        rl.drawText(rl.textFormat("%i FPS", .{rl.getFPS()}), 5, 5, 20, .white);
    }
}
