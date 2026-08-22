const std = @import("std");
const rl = @import("raylib");

const SCREEN_WIDTH = 1500;
const SCREEN_HEIGHT = 1000;
const BG_COLOR = rl.Color{ .a = 255, .r = 25, .g = 23, .b = 36 };
const BOID_COLOR = rl.Color{ .a = 255, .r = 144, .g = 140, .b = 170 };

const FLOCK_SIZE = 200;
const PERCEPTION = 100;
const MAX_SPEED = 3;

const Boid = struct {
    id: u16,
    pos: rl.Vector2,
    vel: rl.Vector2,
    accel: rl.Vector2,
    perception: f32,

    pub fn init(id: usize, rand: std.Random) Boid {
        var vel = rl.Vector2{
            .x = rand.float(f32) * 2 - 1,
            .y = rand.float(f32) * 2 - 1,
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
        var wish_dir = rl.Vector2.zero();
        var boid_count: f32 = 0;
        const strength = 0.05;

        for (flock) |*boid| {
            if (self.id != boid.id) {
                const dist = self.pos.subtract(boid.pos).length();

                if (dist < self.perception) {
                    boid_count += 1;
                    wish_dir = wish_dir.add(boid.vel);
                }
            }
        }

        if (boid_count > 0) {
            wish_dir = wish_dir.scale(1.0 / boid_count);
            const wish_vel = wish_dir.subtract(self.vel).scale(strength);

            self.*.accel = self.*.accel.add(wish_vel);
        }
    }

    pub fn cohesion(self: *Boid, flock: []const Boid) void {
        var wish_pos = rl.Vector2.zero();
        var boid_count: f32 = 0;
        const strength = 0.1;

        for (flock) |*boid| {
            if (self.id != boid.id) {
                const dist = self.pos.subtract(boid.pos).length();

                if (dist < self.perception) {
                    boid_count += 1;
                    wish_pos = wish_pos.add(boid.pos);
                }
            }
        }

        if (boid_count > 0) {
            wish_pos = wish_pos.scale(1.0 / boid_count);
            const wish_vel = wish_pos.subtract(self.pos).scale(strength);

            self.*.accel = self.*.accel.add(wish_vel);
        }
    }

    pub fn seperation(self: *Boid, flock: []const Boid) void {
        var wish_dir = rl.Vector2.zero();
        var boid_count: f32 = 0;
        const strength = 0.075;

        for (flock) |*boid| {
            if (self.id != boid.id) {
                const dist = self.pos.subtract(boid.pos).length();

                if (dist < self.perception) {
                    boid_count += 1;

                    var diff = self.pos.subtract(boid.pos);

                    diff = diff.scale(PERCEPTION / dist);

                    wish_dir = wish_dir.add(diff);
                }
            }
        }

        if (boid_count > 0) {
            wish_dir = wish_dir.scale(1.0 / boid_count);
            const wish_vel = wish_dir.scale(strength);

            self.*.accel = self.*.accel.add(wish_vel);
        }
    }

    pub fn focus(self: *Boid) void {
        var wish_dir = rl.Vector2.zero();
        const strength = 0.2;

        if (rl.isMouseButtonDown(rl.MouseButton.left)) {
            wish_dir = rl.getMousePosition().subtract(self.pos);
        }

        wish_dir = wish_dir.normalize().scale(strength);

        self.*.accel = self.*.accel.add(wish_dir);
        rl.drawCircleV(rl.getMousePosition(), 5, rl.Color.white);
    }

    pub fn move(self: *Boid) void {
        self.vel = self.vel.add(self.accel);

        // self.vel = self.vel.clampValue(0.0, MAX_SPEED);
        self.vel = self.vel.normalize().scale(MAX_SPEED);

        self.pos = self.pos.add(self.vel);

        self.accel = rl.Vector2.zero();

        if (self.pos.x > SCREEN_WIDTH) {
            self.pos.x = 0;
        } else if (self.pos.x < 0) {
            self.pos.x = SCREEN_WIDTH;
        }

        if (self.pos.y > SCREEN_HEIGHT) {
            self.pos.y = 0;
        } else if (self.pos.y < 0) {
            self.pos.y = SCREEN_HEIGHT;
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

        if (self.id == 0) {
            rl.drawLineV(self.pos, self.pos.add(self.vel.scale(50)), BOID_COLOR);
            rl.drawCircleLinesV(self.pos, self.perception, rl.Color.white.alpha(0.5));
        }
    }
};

pub fn main(init: std.process.Init) anyerror!void {
    const io = init.io;
    const rng_impl: std.Random.IoSource = .{ .io = io };
    const rand = rng_impl.interface();

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "flocking");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var flock: [FLOCK_SIZE]Boid = undefined;

    for (&flock, 0..) |*single, i| {
        single.* = Boid.init(i, rand);
    }

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(BG_COLOR);

        for (&flock) |*boid| {
            boid.*.seperation(&flock);
            boid.*.alignment(&flock);
            boid.*.cohesion(&flock);
            boid.*.focus();
            boid.*.move();
            boid.*.draw();
        }
    }
}
