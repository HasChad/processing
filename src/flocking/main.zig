const std = @import("std");
const rl = @import("raylib");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 600;
const BG_COLOR = rl.Color{ .a = 255, .r = 25, .g = 23, .b = 36 };
const BOID_COLOR = rl.Color{ .a = 255, .r = 144, .g = 140, .b = 170 };

const FLOCK_SIZE = 200;
const PERCEPTION = 50;

const Boid = struct {
    id: u16,
    pos: rl.Vector2,
    vel: rl.Vector2,
    accel: rl.Vector2,
    perception: f32,

    pub fn init(id: usize, rand: std.Random) Boid {
        var vel = rl.Vector2{
            .x = rand.float(f32),
            .y = rand.float(f32),
        };

        vel = vel.normalize();

        return Boid{
            .id = @intCast(id),
            .pos = rl.Vector2{
                .x = rand.float(f32) * SCREEN_WIDTH,
                .y = rand.float(f32) * SCREEN_HEIGHT,
            },
            .vel = vel,
            .accel = rl.Vector2.zero(),
            .perception = PERCEPTION,
        };
    }

    pub fn alignment(self: *Boid, flock: []const Boid) void {
        var wish_vel = rl.Vector2.zero();
        var boid_count: u16 = 0;

        for (flock) |*boid| {
            if (self.id != boid.id) {
                const dist = self.pos.subtract(boid.pos).length();

                if (dist < self.perception) {
                    boid_count += 1;
                    wish_vel = wish_vel.add(boid.vel);
                }
            }
        }

        if (boid_count == 0) {
            return;
        }

        wish_vel.x = wish_vel.x / boid_count;
        wish_vel.y = wish_vel.y / boid_count;

        self.*.accel = wish_vel.subtract(self.vel);

        self.*.accel.x = self.accel.x / 100;
        self.*.accel.y = self.accel.y / 100;
    }

    pub fn move(self: *Boid) void {
        self.vel = self.vel.add(self.accel);

        self.pos = self.pos.add(self.vel);

        if (self.pos.x > SCREEN_WIDTH) {
            self.pos.x = 0;
        } else if (self.pos.x < 0) {
            self.pos.x = SCREEN_WIDTH;
        }

        if (self.pos.y > SCREEN_HEIGHT) {
            self.pos.y = 0;
        } else if (self.pos.x < 0) {
            self.pos.x = SCREEN_HEIGHT;
        }
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

        rl.drawTriangle(p1, p2, p3, BOID_COLOR);

        rl.drawLineV(self.pos, self.pos.add(self.vel.scale(50)), BOID_COLOR);

        if (self.id == 0) {
            rl.drawCircleLinesV(self.pos, self.perception, rl.Color.white.alpha(0.5));
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

    var flock: [FLOCK_SIZE]Boid = undefined;

    for (&flock, 0..) |*single, i| {
        single.* = Boid.init(i, rand);
    }

    while (!rl.windowShouldClose()) {
        for (&flock) |*single| {
            single.*.move();
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(BG_COLOR);

        for (&flock) |*single| {
            single.*.alignment(&flock);
            single.*.draw();
        }
    }
}
