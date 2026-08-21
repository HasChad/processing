const std = @import("std");
const rl = @import("raylib");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 600;
const BG_COLOR = rl.Color{ .a = 255, .r = 25, .g = 23, .b = 36 };
const RAIN_COLOR = rl.Color{ .a = 255, .r = 144, .g = 140, .b = 170 };

const Drop = struct {
    x: f32,
    y: f32,
    vy: f32,

    pub fn init(rand: std.Random) Drop {
        return Drop{
            .x = rand.float(f32) * SCREEN_WIDTH,
            .y = rand.float(f32) * 500 - 700,
            .vy = rand.float(f32) * 1000 + 500,
        };
    }

    pub fn draw(self: Drop) void {
        var color = RAIN_COLOR;

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

        if (self.y > SCREEN_HEIGHT) {
            self.* = Drop.init(rand);
        }
    }
};

pub fn main(init: std.process.Init) anyerror!void {
    const io = init.io;
    const rng_impl: std.Random.IoSource = .{ .io = io };
    const rand = rng_impl.interface();

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "rain");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var drop: [200]Drop = undefined;

    for (&drop) |*single| {
        single.* = Drop.init(rand);
    }

    while (!rl.windowShouldClose()) {
        for (&drop) |*single| {
            single.*.move(rand);
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(BG_COLOR);

        for (&drop) |*single| {
            single.*.draw();
        }
    }
}
