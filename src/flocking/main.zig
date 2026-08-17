const std = @import("std");
const rl = @import("raylib");

const screenWidth = 800;
const screenHeight = 600;
const bg_color = rl.Color{ .a = 255, .r = 25, .g = 23, .b = 36 };
const boid_color = rl.Color{ .a = 255, .r = 144, .g = 140, .b = 170 };

const Boid = struct {
    pos: rl.Vector2,
    vel: rl.Vector2,

    pub fn init(rand: std.Random) Boid {
        var vel = rl.Vector2{
            .x = rand.float(f32),
            .y = rand.float(f32),
        };

        vel = vel.normalize();

        return Boid{
            .pos = rl.Vector2{
                .x = rand.float(f32) * screenWidth,
                .y = rand.float(f32) * screenHeight,
            },
            .vel = vel,
        };
    }

    pub fn draw(self: Boid) void {
        const up = rl.Vector2{ .x = 0, .y = -1 };
        const rot = up.angle(self.vel);

        var p1 = rl.Vector2{ .x = -5, .y = 5 };
        var p2 = rl.Vector2{ .x = 5, .y = 5 };
        var p3 = rl.Vector2{ .x = 0, .y = -10 };

        p1 = p1.rotate(rot).add(self.pos);
        p2 = p2.rotate(rot).add(self.pos);
        p3 = p3.rotate(rot).add(self.pos);

        rl.drawTriangle(p1, p2, p3, boid_color);

        // rl.drawCircleV(self.pos, 5.0, boid_color);

        rl.drawLineV(
            self.pos,
            self.pos.add(self.vel.normalize().scale(50)),
            boid_color,
        );
    }

    pub fn move(self: *Boid, rand: std.Random) void {
        _ = rand;

        self.pos = self.pos.add(self.vel);

        if (self.pos.x > screenWidth) {
            self.pos.x = 0;
        } else if (self.pos.x < 0) {
            self.pos.x = screenWidth;
        }

        if (self.pos.y > screenHeight) {
            self.pos.y = 0;
        } else if (self.pos.x < 0) {
            self.pos.x = screenHeight;
        }
    }
};

pub fn main(init: std.process.Init) anyerror!void {
    const io = init.io;
    const rng_impl: std.Random.IoSource = .{ .io = io };
    const rand = rng_impl.interface();

    rl.initWindow(screenWidth, screenHeight, "rain");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var flock: [50]Boid = undefined;

    for (&flock) |*single| {
        single.* = Boid.init(rand);
    }

    while (!rl.windowShouldClose()) {
        for (&flock) |*single| {
            single.*.move(rand);
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(bg_color);

        for (&flock) |*single| {
            single.*.draw();
        }
    }
}
